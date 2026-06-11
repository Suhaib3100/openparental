package app.monii.managed.supervisor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import app.monii.managed.R
import app.monii.managed.survival.SurvivalLog

/**
 * Spike #1 anchor. It does nothing useful yet — it only proves the foreground
 * service can stay alive. In the real managed app this becomes the supervisor
 * that starts typed child services (enforcement, vpn, location, screen-view).
 *
 *   onStartCommand ─► startForeground(specialUse) ─► heartbeat loop (15s)
 *        ▲                                                 │
 *        └──── START_STICKY / BootReceiver / Watchdog ◄────┘   (restart paths)
 */
class SupervisorService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private val heartbeat = object : Runnable {
        override fun run() {
            SurvivalLog.heartbeat(this@SupervisorService)
            handler.postDelayed(this, HEARTBEAT_MS)
        }
    }

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
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // User swiped the app away. Log it; START_STICKY / the watchdog bring us
        // back, so we can measure swipe-away survival per OEM.
        SurvivalLog.record(this, SurvivalLog.TASK_REMOVED)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        running = false
        handler.removeCallbacks(heartbeat)
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
