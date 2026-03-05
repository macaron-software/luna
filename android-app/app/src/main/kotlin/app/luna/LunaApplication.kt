package app.luna

import android.app.Application
import app.luna.services.VaultService

/**
 * LunaApplication — point d'entrée de l'application Android.
 * Aucune initialisation réseau, aucun SDK analytics ou télémétrie.
 */
class LunaApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Charger la bibliothèque native Rust (générée par cargo-ndk)
        System.loadLibrary("luna_core")
    }

    override fun onTerminate() {
        super.onTerminate()
        VaultService.lock()
    }
}
