package app.monii.managed.net

import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path

interface MoniiApi {
    // --- bootstrap (no auth) ---
    @POST("pairings/claim")
    suspend fun claim(@Body body: ClaimRequest): ClaimResponse

    @POST("devices/token")
    suspend fun reauth(@Body body: ReauthRequest): ReauthResponse

    // --- device token required (added by AuthInterceptor) ---
    @POST("heartbeat")
    suspend fun heartbeat(@Body body: HeartbeatRequest): HeartbeatAck

    @GET("commands/pending")
    suspend fun pendingCommands(): List<CommandDto>

    @POST("commands/{id}/ack")
    suspend fun ackCommand(@Path("id") id: String): CommandDto

    @POST("commands/{id}/result")
    suspend fun commandResult(
        @Path("id") id: String,
        @Body body: CommandResultRequest,
    ): CommandDto

    @POST("events")
    suspend fun ingestEvents(@Body body: IngestEventsRequest): IngestResponse

    @POST("tamper")
    suspend fun reportTamper(@Body body: TamperRequest): TamperDto

    @POST("locations")
    suspend fun reportLocation(@Body body: LocationRequest): LocationDto

    @PATCH("devices/me")
    suspend fun selfUpdate(@Body body: SelfUpdateRequest): DeviceDto

    @POST("content")
    suspend fun ingestContent(@Body body: IngestContentRequest): IngestContentResponse
}
