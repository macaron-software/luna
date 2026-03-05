package app.luna.services

import android.content.Context
import android.os.Build
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * HealthConnectManager — intégration optionnelle Health Connect (API 26+).
 * Wrappé derrière un check runtime pour compatibilité API 23+.
 * Seules les données menstruelles et la température basale sont échangées.
 */
object HealthConnectManager {

    fun isAvailable(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

    /**
     * Vérifie si Health Connect est installé sur l'appareil.
     * Health Connect est une app séparée (pas incluse dans le système avant Android 14).
     */
    fun isInstalled(context: Context): Boolean {
        if (!isAvailable()) return false
        return try {
            context.packageManager.getPackageInfo("com.google.android.apps.healthdata", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Écrit un enregistrement de flux menstruel.
     * En production, utiliser androidx.health.connect.client directement.
     */
    suspend fun writeMenstrualFlow(context: Context, date: String, flow: String): Boolean =
        withContext(Dispatchers.IO) {
            if (!isAvailable() || !isInstalled(context)) return@withContext false
            // TODO: Implémenter avec androidx.health.connect.client
            // Nécessite: implementation("androidx.health.connect:connect-client:1.1.0-rc01")
            false
        }

    /**
     * Lit la dernière température basale depuis Health Connect.
     */
    suspend fun readLatestBBT(context: Context): Double? =
        withContext(Dispatchers.IO) {
            if (!isAvailable() || !isInstalled(context)) return@withContext null
            // TODO: Implémenter avec BodyTemperatureMeasurementRecord
            null
        }
}
