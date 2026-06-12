package app.monii.managed.admin

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class AdminManager(context: Context) {
    private val dpm: DevicePolicyManager? =
        context.getSystemService(DevicePolicyManager::class.java)
    private val component = ComponentName(context, MoniiDeviceAdminReceiver::class.java)

    fun isActive(): Boolean = dpm?.isAdminActive(component) == true

    /** Lock the screen now. Throws if admin isn't active (surfaced as a command error). */
    fun lockNow() {
        val mgr = dpm ?: throw IllegalStateException("DevicePolicyManager unavailable")
        if (!isActive()) throw IllegalStateException("device admin not active")
        mgr.lockNow()
    }

    fun enableIntent(): Intent =
        Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            .putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
            .putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "OpenParental needs device admin to lock the device remotely.",
            )
}
