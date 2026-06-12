package app.monii.managed.sync

import android.content.Context
import android.os.BatteryManager
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import app.monii.managed.admin.AdminManager
import app.monii.managed.commands.CommandDispatcher
import app.monii.managed.identity.DeviceStore
import app.monii.managed.repo.MoniiRepository

/**
 * WorkManager backstop (15 min): heartbeat + flush buffered events + pull/execute
 * commands. The Supervisor runs a faster loop while alive; this guarantees the
 * device still syncs after the OEM kills the service.
 */
class SyncWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val store = DeviceStore(applicationContext)
        if (!store.isPaired()) return Result.success()
        val repo = MoniiRepository(applicationContext, store)
        val admin = AdminManager(applicationContext)
        return try {
            repo.heartbeat(batteryPct())
            repo.flushEvents()
            CommandDispatcher(applicationContext, repo, admin).syncAndExecute()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private fun batteryPct(): Int? {
        val bm = applicationContext.getSystemService(BatteryManager::class.java) ?: return null
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return if (level in 0..100) level else null
    }
}
