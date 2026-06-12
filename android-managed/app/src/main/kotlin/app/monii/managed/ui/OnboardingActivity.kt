package app.monii.managed.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import app.monii.managed.R
import app.monii.managed.admin.AdminManager
import app.monii.managed.databinding.ActivityOnboardingBinding
import app.monii.managed.databinding.ItemPermissionBinding
import app.monii.managed.permissions.SpecialAccess
import app.monii.managed.vpn.VpnFilterService

/**
 * Guided special-access setup. Each step opens the right Settings screen and the
 * list re-checks its status every time the user returns. Optional steps (OEM
 * autostart, notifications) don't block "all set".
 */
class OnboardingActivity : AppCompatActivity() {

    private data class Step(
        val title: String,
        val desc: String,
        val granted: () -> Boolean,
        val open: () -> Unit,
        val optional: Boolean = false,
    )

    private lateinit var binding: ActivityOnboardingBinding
    private lateinit var steps: List<Step>
    private val rows = mutableListOf<ItemPermissionBinding>()

    private val notifPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { refresh() }

    private val vpnConsent =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == RESULT_OK) startVpn()
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityOnboardingBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val admin = AdminManager(this)
        steps = listOf(
            Step(
                "Notifications",
                "Let monii show its ongoing status.",
                { notificationsGranted() },
                { requestNotifications() },
                optional = true,
            ),
            Step(
                "Unrestricted battery",
                "Stops the system from killing monii in the background.",
                { isIgnoringBattery() },
                { requestIgnoreBattery() },
            ),
            Step(
                "Accessibility",
                "Lets monii enforce app and time limits.",
                { SpecialAccess.isAccessibilityEnabled(this) },
                { startSafe(SpecialAccess.accessibilitySettingsIntent()) },
            ),
            Step(
                "Usage access",
                "Lets monii measure screen time.",
                { SpecialAccess.isUsageAccessGranted(this) },
                { startSafe(SpecialAccess.usageAccessSettingsIntent()) },
            ),
            Step(
                "Device admin",
                "Lets monii lock the device remotely.",
                { admin.isActive() },
                { startSafe(admin.enableIntent()) },
            ),
            Step(
                "Content filter",
                "Block adult & unsafe sites with a private on-device DNS filter.",
                { false },
                { enableContentFilter() },
                optional = true,
            ),
            Step(
                "Auto-start (some phones)",
                "On Xiaomi/Oppo/Vivo, allow monii to start on boot.",
                { false },
                { openOemAutostart() },
                optional = true,
            ),
        )
        buildRows()
        binding.btnDone.setOnClickListener { finish() }
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    private fun buildRows() {
        steps.forEach { step ->
            val row = ItemPermissionBinding.inflate(layoutInflater, binding.steps, false)
            row.itemTitle.text = step.title
            row.itemDesc.text = step.desc
            row.itemAction.setOnClickListener { step.open() }
            binding.steps.addView(row.root)
            rows.add(row)
        }
    }

    private fun refresh() {
        steps.forEachIndexed { i, step ->
            val row = rows[i]
            val granted = runCatching { step.granted() }.getOrDefault(false)
            if (granted) {
                row.itemStatus.text = "✓ Granted"
                row.itemAction.text = getString(R.string.onb_open)
            } else {
                row.itemStatus.text = if (step.optional) "Optional" else "Needs setup"
                row.itemAction.text = getString(R.string.onb_open)
            }
        }
    }

    private fun startSafe(intent: Intent) {
        runCatching { startActivity(intent) }
    }

    private fun enableContentFilter() {
        val prep = VpnService.prepare(this)
        if (prep != null) vpnConsent.launch(prep) else startVpn()
    }

    private fun startVpn() {
        runCatching { startService(Intent(this, VpnFilterService::class.java)) }
    }

    private fun notificationsGranted(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notifPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun isIgnoringBattery(): Boolean {
        val pm = getSystemService(PowerManager::class.java) ?: return false
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    @Suppress("BatteryLife")
    private fun requestIgnoreBattery() {
        runCatching {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                ),
            )
        }.onFailure {
            startSafe(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun openOemAutostart() {
        val candidates = listOf(
            "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        )
        for ((pkg, cls) in candidates) {
            if (runCatching { startActivity(Intent().setClassName(pkg, cls)) }.isSuccess) return
        }
        startSafe(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
        )
    }
}
