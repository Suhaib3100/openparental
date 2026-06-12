package app.monii.managed.data

import android.content.Context
import com.google.gson.Gson

/** Latest policy received via SET_POLICY. The Phase 5 enforcement engine reads it. */
object PolicyStore {
    private const val PREFS = "monii_policy"

    fun save(context: Context, payload: Map<String, Any?>?) {
        val json = Gson().toJson(payload ?: emptyMap<String, Any?>())
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString("policy", json).apply()
    }

    fun loadJson(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("policy", null)
}
