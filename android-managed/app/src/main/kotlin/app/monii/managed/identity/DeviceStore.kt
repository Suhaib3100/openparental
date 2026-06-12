package app.monii.managed.identity

import android.content.Context

/**
 * Device identity + backend base URL. SharedPreferences for now; the device
 * token/secret should move to EncryptedSharedPreferences before any real ship.
 */
class DeviceStore(context: Context) {
    private val prefs =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun baseUrl(): String = prefs.getString("base_url", DEFAULT_BASE) ?: DEFAULT_BASE
    fun setBaseUrl(url: String) = prefs.edit().putString("base_url", url.trim()).apply()

    fun token(): String? = prefs.getString("device_token", null)
    fun setToken(token: String) = prefs.edit().putString("device_token", token).apply()

    fun deviceId(): String? = prefs.getString("device_id", null)
    fun deviceSecret(): String? = prefs.getString("device_secret", null)

    fun isPaired(): Boolean = token() != null && deviceId() != null

    fun savePairing(deviceId: String, token: String, secret: String) {
        prefs.edit()
            .putString("device_id", deviceId)
            .putString("device_token", token)
            .putString("device_secret", secret)
            .apply()
    }

    fun clearPairing() {
        prefs.edit()
            .remove("device_id")
            .remove("device_token")
            .remove("device_secret")
            .apply()
    }

    fun fcmToken(): String? = prefs.getString("fcm_token", null)

    fun setFcmToken(token: String) {
        if (token != fcmToken()) {
            prefs.edit().putString("fcm_token", token).putBoolean("fcm_needs_sync", true).apply()
        }
    }

    fun fcmNeedsSync(): Boolean =
        prefs.getBoolean("fcm_needs_sync", false) && fcmToken() != null

    fun markFcmSynced() = prefs.edit().putBoolean("fcm_needs_sync", false).apply()

    companion object {
        private const val PREFS = "monii_identity"

        // 10.0.2.2 = the host machine from the Android emulator.
        const val DEFAULT_BASE = "http://10.0.2.2:3000"
    }
}
