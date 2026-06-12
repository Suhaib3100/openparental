package app.monii.managed.supervisor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import app.monii.managed.R
import app.monii.managed.admin.AdminManager
import app.monii.managed.commands.CommandDispatcher
import app.monii.managed.identity.DeviceStore
import app.monii.managed.repo.MoniiRepository
import app.monii.managed.survival.SurvivalLog
import app.monii.managed.sync.SyncScheduler
import app.monii.managed.tamper.TamperWatchdog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * The managed-app anchor. Keeps a foreground service alive (survival, from spike
 * #1) AND, once paired, runs a fast sync loop every 60s: heartbeat + flush events
 * + pull and execute commands. WorkManager (SyncWorker) is the slower backstop for
 * when the OEM kills this service.
 *
 *   onStartCommand ─► startForeground ─► survival heartbeat (15s, local)
 *                                     └► sync loop (60s, backend) when paired
 */
class SupervisorService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private val heartbeat = object : Runnable {
        override fun run() {
            SurvivalLog.heartbeat(this@SupervisorService)
            handler.postDelayed(this, HEARTBEAT_MS)
        }
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var syncJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundCompat()
        SurvivalLog.record(
            this,
            SurvivalLog.START,
            "(${Build.MANUFACTURER} ${Build.MODEL}, API ${Build.VERSION.SDK_INT})",
        )
        running = true
        handler.removeCallbacks(heartbeat)
        handler.post(heartbeat)
        SyncScheduler.schedule(this)
        startSyncLoop()
        return START_STICKY
    }

    private fun startSyncLoop() {
        if (syncJob?.isActive == true) return
        val app = applicationContext
        val store = DeviceStore(app)
        val repo = MoniiRepository(app, store)
        val dispatcher = CommandDispatcher(app, repo, AdminManager(app))
        val tamper = TamperWatchdog(app)
        syncJob = scope.launch {
            while (isActive) {
                if (store.isPaired()) {
                    runCatching {
                        repo.heartbeat(batteryPct())
                        repo.flushEvents()
                        dispatcher.syncAndExecute()
                        tamper.check(repo)
                    }
                }
                delay(SYNC_MS)
            }
        }
    }

    private fun batteryPct(): Int? {
        val bm = getSystemService(BatteryManager::class.java) ?: return null
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return if (level in 0..100) level else null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        SurvivalLog.record(this, SurvivalLog.TASK_REMOVED)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        running = false
        handler.removeCallbacks(heartbeat)
        scope.cancel()
        SurvivalLog.record(this, SurvivalLog.DESTROY)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundCompat() {
        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.fgs_title))
            .setContentText(getString(R.string.fgs_text))
            .setSmallIcon(R.drawable.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    private fun createChannel() {
        val mgr = getSystemService(NotificationManager::class.java) ?: return
        if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Monii supervisor",
                NotificationManager.IMPORTANCE_LOW,
            )
            ch.description = "Keeps monii running."
            mgr.createNotificationChannel(ch)
        }
    }

    companion object {
        private const val CHANNEL_ID = "monii_supervisor"
        private const val NOTIF_ID = 1001
        private const val HEARTBEAT_MS = 15_000L
        private const val SYNC_MS = 60_000L

        @Volatile
        var running = false
            private set

        fun start(context: Context) {
            val i = Intent(context, SupervisorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }
    }
}
