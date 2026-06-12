package app.monii.managed.data

import android.content.Context
import app.monii.managed.net.ContentItemDto
import com.google.gson.Gson
import java.io.File

/** Offline queue for content archive batches (browser, notifications, …). */
class ContentBuffer(context: Context) {
    private val file = File(context.filesDir, "content_buffer.jsonl")
    private val gson = Gson()

    @Synchronized
    fun add(item: ContentItemDto) {
        file.appendText(gson.toJson(item) + "\n")
    }

    @Synchronized
    fun drainAndClear(): List<ContentItemDto> {
        if (!file.exists()) return emptyList()
        val items = file.readLines()
            .filter { it.isNotBlank() }
            .mapNotNull {
                runCatching { gson.fromJson(it, ContentItemDto::class.java) }.getOrNull()
            }
        file.writeText("")
        return items
    }

    @Synchronized
    fun readd(items: List<ContentItemDto>) {
        val sb = StringBuilder()
        items.forEach { sb.append(gson.toJson(it)).append("\n") }
        val existing = if (file.exists()) file.readText() else ""
        file.writeText(sb.toString() + existing)
    }
}
