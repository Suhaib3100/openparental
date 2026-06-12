package app.monii.managed.net

// Request/response shapes. Field names match the backend's camelCase JSON 1:1
// (Gson uses the Kotlin property names directly).

data class ClaimRequest(
    val token: String,
    val deviceName: String?,
    val manufacturer: String?,
    val model: String?,
    val osVersion: String?,
    val appVersion: String?,
    val fcmToken: String? = null,
)

data class ClaimResponse(
    val deviceId: String,
    val deviceToken: String,
    val deviceSecret: String,
)

data class ReauthRequest(val deviceId: String, val secret: String)

data class HeartbeatAck(val ok: Boolean)

data class ReauthResponse(val deviceId: String, val deviceToken: String)

data class HeartbeatRequest(val batteryPct: Int?)

data class CommandDto(
    val id: String,
    val type: String,
    val payload: Map<String, Any?>?,
    val state: String,
)

data class CommandResultRequest(val result: Map<String, Any?>?, val error: String?)

data class EventInputDto(
    val type: String,
    val data: Map<String, Any?>,
    val occurredAt: String,
)

data class IngestEventsRequest(val events: List<EventInputDto>)

data class IngestResponse(val count: Int)

data class TamperRequest(
    val kind: String,
    val detail: String?,
    val occurredAt: String? = null,
)

data class TamperDto(val id: String)

data class LocationRequest(
    val lat: Double,
    val lng: Double,
    val accuracyM: Double?,
    val occurredAt: String? = null,
)

data class LocationDto(val id: String)

data class SelfUpdateRequest(
    val batteryPct: Int?,
    val osVersion: String?,
    val appVersion: String?,
    val fcmToken: String?,
)

data class DeviceDto(val id: String, val status: String?)
