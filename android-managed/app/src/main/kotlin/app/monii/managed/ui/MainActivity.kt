package app.monii.managed.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import app.monii.managed.admin.AdminManager
import app.monii.managed.commands.CommandDispatcher
import app.monii.managed.databinding.ActivityMainBinding
import app.monii.managed.identity.DeviceStore
import app.monii.managed.repo.MoniiRepository
import app.monii.managed.supervisor.SupervisorService
import app.monii.managed.supervisor.WatchdogScheduler
import app.monii.managed.survival.SurvivalLog
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Device-side console: pair with the backend, see connection + admin state, and
 * (from the spike) the survival diagnostics. The real product hides most of this;
 * it's a developer console for now.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private val fmt = SimpleDateFormat("MM-dd HH:mm:ss", Locale.US)

    private val store by lazy { DeviceStore(this) }
    private val repo by lazy { MoniiRepository(applicationContext, store) }
    private val admin by lazy { AdminManager(this) }

    private val notifPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { render() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        requestNotifPermissionIfNeeded()
        SupervisorService.start(this)
        WatchdogScheduler.schedule(this)

        binding.etBaseUrl.setText(store.baseUrl())

        binding.btnPair.setOnClickListener { pair() }
        binding.btnSync.setOnClickListener { syncNow() }
        binding.btnUnpair.setOnClickListener {
            store.clearPairing(); toast("Unpaired"); render()
        }
        binding.btnEnableAdmin.setOnClickListener {
            runCatching { startActivity(admin.enableIntent()) }
        }

        binding.btnStart.setOnClickListener { SupervisorService.start(this); render() }
        binding.btnRefresh.setOnClickListener { render() }
        binding.btnBattery.setOnClickListener { requestIgnoreBatteryOptimizations() }
        binding.btnAutostart.setOnClickListener { openOemAutostartSettings() }
    }

    override fun onResume() {
        super.onResume()
        render()
    }

    private fun pair() {
        val base = binding.etBaseUrl.text.toString().trim()
        val code = binding.etCode.text.toString().trim()
        if (base.isEmpty() || code.isEmpty()) {
            toast("Enter URL and code")
            return
        }
        binding.btnPair.isEnabled = false
        lifecycleScope.launch {
            val result = runCatching { repo.claim(base, code) }
            binding.btnPair.isEnabled = true
            result.onSuccess {
                toast("Paired ✓")
                SupervisorService.start(this@MainActivity)
                render()
            }.onFailure {
                toast("Pair failed: ${it.message}")
            }
        }
    }

    private fun syncNow() {
        if (!store.isPaired()) {
            toast("Not paired")
            return
        }
        binding.btnSync.isEnabled = false
        lifecycleScope.launch {
            val result = runCatching {
                repo.heartbeat(null)
                repo.flushEvents()
                CommandDispatcher(applicationContext, repo, admin).syncAndExecute()
            }
            binding.btnSync.isEnabled = true
            result.onSuccess { toast("Synced ($it cmd)"); render() }
                .onFailure { toast("Sync failed: ${it.message}") }
        }
    }

    private fun render() {
        binding.txtConnection.text = buildString {
            appendLine("Backend: ${store.baseUrl()}")
            appendLine("Paired:  ${store.isPaired()}")
            store.deviceId()?.let { appendLine("Device:  $it") }
            appendLine("Admin:   ${if (admin.isActive()) "active" else "not enabled"}")
        }
        val s = SurvivalLog.snapshot(this)
        val now = System.currentTimeMillis()
        binding.txtStatus.text = buildString {
            appendLine("Device:  ${Build.MANUFACTURER} ${Build.MODEL}")
            appendLine("Android: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
            appendLine("Battery-opt ignored: ${isIgnoringBatteryOptimizations()}")
            appendLine("Service running:   ${SupervisorService.running}")
            appendLine("Uptime this run:   ${durationSince(s.serviceStartAt, now)}")
            appendLine("Last heartbeat:    ${ago(s.lastHeartbeatAt, now)}")
            appendLine("Starts/boot/watchdog: ${s.startCount}/${s.bootCount}/${s.watchdogCount}")
        }
        binding.txtLog.text = SurvivalLog.tail(this)
    }

    private fun toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()

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
        runCatching {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
            )
        }
    }
}
