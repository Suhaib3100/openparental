package app.monii.managed.vpn

import android.content.Context
import app.monii.managed.data.PolicyStore
import com.google.gson.Gson
import com.google.gson.JsonObject

/**
 * Custom per-domain blocks from the policy's `blockedDomains`. Category filtering
 * (adult / malware) is handled upstream by Cloudflare-for-Families, so this only
 * needs the family's explicit additions. Matches a domain or any parent suffix.
 */
class DomainBlocklist(context: Context) {
    private val blocked: Set<String> = load(context)

    fun isBlocked(domain: String): Boolean {
        if (blocked.isEmpty()) return false
        var d = domain
        while (true) {
            if (blocked.contains(d)) return true
            val dot = d.indexOf('.')
            if (dot < 0) return false
            d = d.substring(dot + 1)
        }
    }

    private fun load(context: Context): Set<String> {
        val json = PolicyStore.loadJson(context) ?: return emptySet()
        return runCatching {
            val obj = Gson().fromJson(json, JsonObject::class.java)
            obj.getAsJsonArray("blockedDomains")
                ?.mapNotNull { runCatching { it.asString.lowercase() }.getOrNull() }
                ?.toSet() ?: emptySet()
        }.getOrDefault(emptySet())
    }
}
