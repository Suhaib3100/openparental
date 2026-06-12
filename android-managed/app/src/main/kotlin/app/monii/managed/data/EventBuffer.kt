package app.monii.managed.data

import android.content.Context
import app.monii.managed.net.EventInputDto
import com.google.gson.Gson
import java.io.File

/** File-backed offline event queue (JSON lines). Swapped for Room in a later pass. */
class EventBuffer(context: Context) {
    private val file = File(context.filesDir, "event_buffer.jsonl")
    private val gson = Gson()

    @Synchronized
    fun add(event: EventInputDto) {
        file.appendText(gson.toJson(event) + "\n")
    }

    @Synchronized
    fun drainAndClear(): List<EventInputDto> {
        if (!file.exists()) return emptyList()
        val items = file.readLines()
            .filter { it.isNotBlank() }
            .mapNotNull { runCatching { gson.fromJson(it, EventInputDto::class.java) }.getOrNull() }
        file.writeText("")
        return items
    }

    /** Re-queue items whose upload failed, ahead of anything buffered since. */
    @Synchronized
    fun readd(items: List<EventInputDto>) {
        val sb = StringBuilder()
        items.forEach { sb.append(gson.toJson(it)).append("\n") }
        val existing = if (file.exists()) file.readText() else ""
        file.writeText(sb.toString() + existing)
    }
}
