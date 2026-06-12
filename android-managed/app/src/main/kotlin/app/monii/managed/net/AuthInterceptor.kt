package app.monii.managed.net

import app.monii.managed.identity.DeviceStore
import okhttp3.Interceptor
import okhttp3.Response

/** Adds the stored device token as a Bearer header. Bootstrap calls (claim,
 *  reauth) ignore it server-side, so it's safe to attach unconditionally. */
class AuthInterceptor(private val store: DeviceStore) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = store.token()
        val request =
            if (token != null) {
                chain.request().newBuilder()
                    .addHeader("Authorization", "Bearer $token")
                    .build()
            } else {
                chain.request()
            }
        return chain.proceed(request)
    }
}
