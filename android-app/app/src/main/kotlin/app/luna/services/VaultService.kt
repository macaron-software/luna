package app.luna.services

import android.content.Context
import uniffi.luna_core.LunaEngine

/**
 * VaultService — singleton gérant l'état du vault Rust.
 * Maintenu en mémoire le temps que l'app est au premier plan.
 * Null = vault verrouillé.
 */
object VaultService {

    @Volatile
    var engine: LunaEngine? = null
        private set

    val isUnlocked: Boolean get() = engine != null

    fun setEngine(e: LunaEngine) {
        engine = e
    }

    fun lock() {
        engine = null
    }

    fun getDbPath(context: Context): String {
        val dir = context.filesDir
        return "${dir.absolutePath}/luna.db"
    }
}
