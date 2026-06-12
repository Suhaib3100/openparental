package app.monii.managed.enforcement

import android.content.Context
import app.monii.managed.data.PolicyStore
import com.google.gson.Gson
import com.google.gson.JsonObject
import java.time.LocalTime

/**
 * Typed view over the policy JSON pushed by SET_POLICY. Shape:
 *   { blockedApps: [pkg], appLimits: [{pkg, dailyMinutes}],
 *     schedules: [{start:"22:00", end:"06:30", blockAll:true}] }
 */
class PolicyRules(
    val blockedApps: Set<String>,
    val appLimits: Map<String, Int>,
    val schedules: List<Schedule>,
) {
    data class Schedule(val start: LocalTime, val end: LocalTime, val blockAll: Boolean)

    fun isWithinBlockingSchedule(now: LocalTime = LocalTime.now()): Boolean =
        schedules.any { it.blockAll && inWindow(now, it.start, it.end) }

    private fun inWindow(now: LocalTime, start: LocalTime, end: LocalTime): Boolean =
        if (start <= end) now >= start && now < end
        else now >= start || now < end // overnight (e.g. 22:00 -> 06:30)

    companion object {
        fun load(context: Context): PolicyRules? {
            val json = PolicyStore.loadJson(context) ?: return null
            return runCatching { parse(json) }.getOrNull()
        }

        private fun parse(json: String): PolicyRules {
            val obj = Gson().fromJson(json, JsonObject::class.java)
            val blocked = obj.getAsJsonArray("blockedApps")
                ?.mapNotNull { runCatching { it.asString }.getOrNull() }
                ?.toSet() ?: emptySet()

            val limits = mutableMapOf<String, Int>()
            obj.getAsJsonArray("appLimits")?.forEach { el ->
                val o = el.asJsonObject
                val pkg = o.get("pkg")?.asString
                val mins = o.get("dailyMinutes")?.asInt
                if (pkg != null && mins != null) limits[pkg] = mins
            }

            val schedules = mutableListOf<Schedule>()
            obj.getAsJsonArray("schedules")?.forEach { el ->
                val o = el.asJsonObject
                val start = o.get("start")?.asString
                val end = o.get("end")?.asString
                val blockAll = o.get("blockAll")?.asBoolean ?: false
                if (start != null && end != null) {
                    runCatching {
                        schedules.add(
                            Schedule(LocalTime.parse(start), LocalTime.parse(end), blockAll),
                        )
                    }
                }
            }
            return PolicyRules(blocked, limits, schedules)
        }
    }
}
