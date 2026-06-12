package app.monii.managed.commands

import android.content.Context
import app.monii.managed.admin.AdminManager
import app.monii.managed.data.PolicyStore
import app.monii.managed.net.CommandDto
import app.monii.managed.repo.MoniiRepository

/**
 * Pull pending commands, execute each, ack + post the result. The server spine
 * is idempotent (ack/result are no-ops once terminal), so re-running after a
 * crash or duplicate wake is safe.
 */
class CommandDispatcher(
    private val context: Context,
    private val repo: MoniiRepository,
    private val admin: AdminManager,
) {
    suspend fun syncAndExecute(): Int {
        val commands = repo.pullCommands()
        for (command in commands) {
            runCatching { repo.ack(command.id) }
            val outcome = runCatching { execute(command) }
            if (outcome.isSuccess) {
                repo.result(command.id, outcome.getOrNull(), null)
            } else {
                repo.result(command.id, null, outcome.exceptionOrNull()?.message ?: "error")
            }
        }
        return commands.size
    }

    private fun execute(command: CommandDto): Map<String, Any?> =
        when (command.type) {
            "LOCK" -> {
                admin.lockNow()
                mapOf("locked" to true)
            }
            "UNLOCK" -> mapOf("noop" to "cannot force-unlock without Device Owner")
            "SET_POLICY" -> {
                PolicyStore.save(context, command.payload)
                mapOf("applied" to true)
            }
            "PING" -> mapOf("pong" to true)
            "REQUEST_LOCATION" -> mapOf("requested" to true) // Phase 6 wires the actual fix
            else -> mapOf("ignored" to command.type)
        }
}
