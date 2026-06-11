package app.monii.managed.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import app.monii.managed.databinding.ActivityMainBinding
import app.monii.managed.supervisor.SupervisorService
import app.monii.managed.supervisor.WatchdogScheduler
import app.monii.managed.survival.SurvivalLog
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Diagnostic dashboard for the survival spike. Start it once, grant unrestricted
 * battery + OEM autostart, then leave the device overnight. Reopen and read:
 * a high start/watchdog/boot count means this OEM kills the anchor aggressively.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private val fmt = SimpleDateFormat("MM-dd HH:mm:ss", Locale.US)

    private val notifPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { render() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        requestNotifPermissionIfNeeded()
        SupervisorService.start(this)
        WatchdogScheduler.schedule(this)

        binding.btnStart.setOnClickListener { SupervisorService.start(this); render() }
        binding.btnRefresh.setOnClickListener { render() }
        binding.btnBattery.setOnClickListener { requestIgnoreBatteryOptimizations() }
        binding.btnAutostart.setOnClickListener { openOemAutostartSettings() }
    }

    override fun onResume() {
        super.onResume()
        render()
    }

    private fun render() {
        val s = SurvivalLog.snapshot(this)
        val now = System.currentTimeMillis()
        binding.txtStatus.text = buildString {
            appendLine("Device:  ${Build.MANUFACTURER} ${Build.MODEL}")
            appendLine("Android: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
            appendLine("FGS type: specialUse")
            appendLine("Battery-opt ignored: ${isIgnoringBatteryOptimizations()}")
            appendLine()
            appendLine("Service running:   ${SupervisorService.running}")
            appendLine("Uptime this run:   ${durationSince(s.serviceStartAt, now)}")
            appendLine("Watching since:    ${durationSince(s.firstStartAt, now)} ago")
            appendLine("Last heartbeat:    ${ago(s.lastHeartbeatAt, now)}")
            appendLine()
            appendLine("Service starts:    ${s.startCount}")
            appendLine("Boot restarts:     ${s.bootCount}")
            appendLine("Watchdog restarts: ${s.watchdogCount}")
        }
        binding.txtLog.text = SurvivalLog.tail(this)
    }

    private fun durationSince(then: Long, now: Long): String {
        if (then <= 0) return "—"
        val secs = (now - then) / 1000
        return "%dh %02dm %02ds".format(secs / 3600, (secs % 3600) / 60, secs % 60)
    }

    private fun ago(then: Long, now: Long): String =
        if (then <= 0) "never" else "${(now - then) / 1000}s ago (${fmt.format(Date(then))})"

    private fun requestNotifPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            notifPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(PowerManager::class.java) ?: return false
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    @Suppress("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        if (isIgnoringBatteryOptimizations()) return
        runCatching {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                ),
            )
        }.onFailure {
            runCatching { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) }
        }
    }

    private fun openOemAutostartSettings() {
        // Best-effort deep-links into the autostart screens of the worst OEMs.
        val candidates = listOf(
            "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
            "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        )
        for ((pkg, cls) in candidates) {
            val i = Intent().setClassName(pkg, cls)
            if (runCatching { startActivity(i) }.isSuccess) return
        }
        // Fallback: app details, where the user can find battery/autostart toggles.
        runCatching {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
            )
        }
    }
}
