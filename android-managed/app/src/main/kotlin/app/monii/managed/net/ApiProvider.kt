package app.monii.managed.net

import app.monii.managed.identity.DeviceStore
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

/** Builds (and caches per base URL) the Retrofit client. */
object ApiProvider {
    @Volatile
    private var cached: Pair<String, MoniiApi>? = null

    @Synchronized
    fun api(store: DeviceStore): MoniiApi {
        val base = ensureSlash(store.baseUrl())
        cached?.let { if (it.first == base) return it.second }
        val client = OkHttpClient.Builder()
            .addInterceptor(AuthInterceptor(store))
            .build()
        val api = Retrofit.Builder()
            .baseUrl(base)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(MoniiApi::class.java)
        cached = base to api
        return api
    }

    private fun ensureSlash(s: String): String = if (s.endsWith("/")) s else "$s/"
}
