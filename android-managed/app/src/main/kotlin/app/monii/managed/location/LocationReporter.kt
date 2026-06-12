package app.monii.managed.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.core.content.ContextCompat
import app.monii.managed.repo.MoniiRepository

/**
 * Best-effort last-known location. The real product uses FusedLocation +
 * geofencing (v1.1); this keeps the dependency surface minimal (no play-services)
 * for now. Needs ACCESS_FINE/COARSE_LOCATION granted.
 */
class LocationReporter(private val context: Context) {
    private val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager

    suspend fun reportLastKnown(repo: MoniiRepository) {
        if (!hasPermission()) return
        val manager = lm ?: return
        var best: Location? = null
        for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
            val loc = runCatching { manager.getLastKnownLocation(provider) }.getOrNull() ?: continue
            if (best == null || loc.time > best.time) best = loc
        }
        val location = best ?: return
        runCatching {
            repo.reportLocation(location.latitude, location.longitude, location.accuracy.toDouble())
        }
    }

    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
}
