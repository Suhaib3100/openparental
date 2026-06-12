package app.monii.managed.repo

import android.content.Context
import android.os.Build
import app.monii.managed.data.EventBuffer
import app.monii.managed.identity.DeviceStore
import app.monii.managed.net.ApiProvider
import app.monii.managed.net.ClaimRequest
import app.monii.managed.net.ClaimResponse
import app.monii.managed.net.CommandDto
import app.monii.managed.net.CommandResultRequest
import app.monii.managed.net.EventInputDto
import app.monii.managed.net.HeartbeatRequest
import app.monii.managed.net.IngestEventsRequest
import app.monii.managed.net.LocationRequest
import app.monii.managed.net.ReauthRequest
import app.monii.managed.net.TamperRequest
import retrofit2.HttpException
import java.time.Instant

/**
 * The device's single conversation point with the backend. Every authenticated
 * call goes through withReauth(): on a 401 it re-mints the device token from the
 * stored secret and retries once, so a token expiry is invisible to callers.
 */
class MoniiRepository(
    private val context: Context,
    private val store: DeviceStore,
) {
    private val api get() = ApiProvider.api(store)
    private val buffer = EventBuffer(context)

    suspend fun claim(baseUrl: String, code: String): ClaimResponse {
        store.setBaseUrl(baseUrl)
        val res = api.claim(
            ClaimRequest(
                token = code.trim(),
                deviceName = "${Build.MANUFACTURER} ${Build.MODEL}",
                manufacturer = Build.MANUFACTURER,
                model = Build.MODEL,
                osVersion = Build.VERSION.RELEASE,
                appVersion = APP_VERSION,
            ),
        )
        store.savePairing(res.deviceId, res.deviceToken, res.deviceSecret)
        return res
    }

    suspend fun heartbeat(batteryPct: Int?) = withReauth {
        api.heartbeat(HeartbeatRequest(batteryPct))
    }

    suspend fun pullCommands(): List<CommandDto> = withReauth { api.pendingCommands() }

    suspend fun ack(id: String) = withReauth { api.ackCommand(id) }

    suspend fun result(id: String, result: Map<String, Any?>?, error: String?) =
        withReauth { api.commandResult(id, CommandResultRequest(result, error)) }

    suspend fun reportTamper(kind: String, detail: String?) =
        withReauth { api.reportTamper(TamperRequest(kind, detail)) }

    suspend fun reportLocation(lat: Double, lng: Double, accuracyM: Double?) =
        withReauth { api.reportLocation(LocationRequest(lat, lng, accuracyM)) }

    fun bufferEvent(type: String, data: Map<String, Any?>) {
        buffer.add(EventInputDto(type, data, Instant.now().toString()))
    }

    suspend fun flushEvents() {
        val items = buffer.drainAndClear()
        if (items.isEmpty()) return
        try {
            withReauth { api.ingestEvents(IngestEventsRequest(items)) }
        } catch (e: Exception) {
            buffer.readd(items)
            throw e
        }
    }

    private suspend fun <T> withReauth(block: suspend () -> T): T =
        try {
            block()
        } catch (e: HttpException) {
            val id = store.deviceId()
            val secret = store.deviceSecret()
            if (e.code() == 401 && id != null && secret != null) {
                val r = api.reauth(ReauthRequest(id, secret))
                store.setToken(r.deviceToken)
                block()
            } else {
                throw e
            }
        }

    companion object {
        const val APP_VERSION = "0.0.1"
    }
}
