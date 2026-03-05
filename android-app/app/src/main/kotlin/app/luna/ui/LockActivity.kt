package app.luna.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import app.luna.R
import app.luna.databinding.ActivityLockBinding
import uniffi.luna_core.LunaEngine
import app.luna.services.KeystoreService
import app.luna.services.VaultService
import kotlinx.coroutines.launch

/**
 * LockActivity — écran de déverrouillage biométrique + PIN.
 * - Tente la biométrie au démarrage
 * - Fallback sur clavier PIN 6 chiffres
 * - Max 5 tentatives puis blocage temporaire
 */
class LockActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLockBinding
    private var attemptsLeft = 5
    private val pinBuffer = StringBuilder()

    companion object {
        fun start(context: Context) {
            context.startActivity(Intent(context, LockActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLockBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupPinKeyboard()
        attemptBiometric()
    }

    // ── Biométrie ──────────────────────────────────────────────────────────

    private fun attemptBiometric() {
        val bm = BiometricManager.from(this)
        if (bm.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) !=
            BiometricManager.BIOMETRIC_SUCCESS) return

        val executor = ContextCompat.getMainExecutor(this)
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                val pin = KeystoreService.readPin(this@LockActivity)
                if (pin != null) openVault(pin)
            }
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                // Afficher le clavier PIN comme fallback
                showPinEntry()
            }
        }

        BiometricPrompt(this, executor, callback).authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle(getString(R.string.lock_biometric_title))
                .setSubtitle(getString(R.string.lock_biometric_subtitle))
                .setNegativeButtonText(getString(R.string.lock_use_pin))
                .build()
        )
    }

    // ── Clavier PIN ────────────────────────────────────────────────────────

    private fun setupPinKeyboard() {
        val buttons = listOf(
            binding.btn0, binding.btn1, binding.btn2, binding.btn3,
            binding.btn4, binding.btn5, binding.btn6, binding.btn7,
            binding.btn8, binding.btn9
        )
        buttons.forEachIndexed { i, btn ->
            btn.setOnClickListener {
                appendDigit(i.toString())
                // a11y
                btn.sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_CLICKED)
            }
        }
        binding.btnDelete.setOnClickListener { deleteDigit() }
        binding.btnDelete.contentDescription = getString(R.string.pin_delete_a11y)
    }

    private fun appendDigit(digit: String) {
        if (pinBuffer.length >= 6 || attemptsLeft == 0) return
        pinBuffer.append(digit)
        updateDots()
        if (pinBuffer.length == 6) attemptUnlock()
    }

    private fun deleteDigit() {
        if (pinBuffer.isNotEmpty()) {
            pinBuffer.deleteCharAt(pinBuffer.lastIndex)
            updateDots()
        }
    }

    private fun updateDots() {
        val dots = listOf(
            binding.dot1, binding.dot2, binding.dot3,
            binding.dot4, binding.dot5, binding.dot6
        )
        dots.forEachIndexed { i, dot ->
            dot.isActivated = i < pinBuffer.length
        }
        // a11y : annoncer le nombre de chiffres saisis
        binding.pinDotsContainer.contentDescription =
            getString(R.string.pin_dots_a11y, pinBuffer.length)
    }

    private fun showPinEntry() {
        binding.pinSection.visibility = android.view.View.VISIBLE
    }

    // ── Déverrouillage vault ───────────────────────────────────────────────

    private fun attemptUnlock() {
        val pin = pinBuffer.toString()
        pinBuffer.clear()
        updateDots()
        lifecycleScope.launch {
            openVault(pin)
        }
    }

    private fun openVault(pin: String) {
        val dbPath = VaultService.getDbPath(this)
        try {
            val engine = LunaEngine.openVault(dbPath, pin)
            VaultService.setEngine(engine)
            // Annoncer déverrouillage
            binding.root.announceForAccessibility(getString(R.string.lock_unlocked_a11y))
            startActivity(Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP))
            finish()
        } catch (e: Exception) {
            attemptsLeft--
            val msg = if (attemptsLeft > 0)
                getString(R.string.lock_wrong_pin)
            else
                getString(R.string.lock_max_attempts)
            binding.errorText.text = msg
            binding.errorText.visibility = android.view.View.VISIBLE
            // a11y : annoncer l'erreur
            binding.root.announceForAccessibility(msg)
        }
    }
}
