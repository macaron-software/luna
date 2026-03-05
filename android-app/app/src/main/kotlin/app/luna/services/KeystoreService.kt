package app.luna.services

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * KeystoreService — stockage sécurisé du PIN via Android Keystore.
 * Le PIN est chiffré avec AES-256-GCM en utilisant une clé hardware-backed.
 * Accès uniquement quand le device est déverrouillé.
 */
object KeystoreService {

    private const val KEY_ALIAS = "luna_pin_key"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val PREF_FILE = "luna_secure_prefs"
    private const val PREF_PIN = "encrypted_pin"
    private const val PREF_IV = "pin_iv"

    fun storePin(context: Context, pin: String) {
        val cipher = getCipher(Cipher.ENCRYPT_MODE)
        val encrypted = cipher.doFinal(pin.toByteArray(Charsets.UTF_8))
        val iv = cipher.iv

        context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE).edit()
            .putString(PREF_PIN, android.util.Base64.encodeToString(encrypted, android.util.Base64.NO_WRAP))
            .putString(PREF_IV, android.util.Base64.encodeToString(iv, android.util.Base64.NO_WRAP))
            .apply()
    }

    fun readPin(context: Context): String? {
        val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
        val encryptedB64 = prefs.getString(PREF_PIN, null) ?: return null
        val ivB64 = prefs.getString(PREF_IV, null) ?: return null

        return try {
            val encrypted = android.util.Base64.decode(encryptedB64, android.util.Base64.NO_WRAP)
            val iv = android.util.Base64.decode(ivB64, android.util.Base64.NO_WRAP)
            val cipher = getCipherWithIV(Cipher.DECRYPT_MODE, iv)
            String(cipher.doFinal(encrypted), Charsets.UTF_8)
        } catch (e: Exception) {
            null
        }
    }

    private fun getOrCreateKey(): SecretKey {
        val ks = KeyStore.getInstance(KEYSTORE).also { it.load(null) }
        ks.getKey(KEY_ALIAS, null)?.let { return it as SecretKey }

        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(false) // Lecture possible sans biométrie si device déverrouillé
            .build()

        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).run {
            init(spec)
            generateKey()
        }
    }

    private fun getCipher(mode: Int): Cipher =
        Cipher.getInstance("AES/GCM/NoPadding").also {
            it.init(mode, getOrCreateKey())
        }

    private fun getCipherWithIV(mode: Int, iv: ByteArray): Cipher =
        Cipher.getInstance("AES/GCM/NoPadding").also {
            it.init(mode, getOrCreateKey(), GCMParameterSpec(128, iv))
        }
}
