package app.luna.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import app.luna.R
import app.luna.services.KeystoreService
import app.luna.services.VaultService
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import uniffi.luna_core.LunaEngine
import kotlinx.coroutines.launch

/**
 * OnboardingActivity — 5 étapes de configuration initiale.
 * Crée le vault Rust avec le PIN choisi à l'étape 4.
 */
class OnboardingActivity : AppCompatActivity() {

    private var step = 0
    private val MAX_STEPS = 5

    companion object {
        fun start(context: Context) =
            context.startActivity(Intent(context, OnboardingActivity::class.java))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_onboarding)
        renderStep()
    }

    private fun renderStep() {
        val progressBar = findViewById<android.widget.ProgressBar>(R.id.onboarding_progress)
        progressBar.progress = ((step + 1) * 100) / MAX_STEPS
        progressBar.contentDescription = getString(R.string.onboarding_step_a11y, step + 1, MAX_STEPS)

        val title = findViewById<TextView>(R.id.onboarding_title)
        val subtitle = findViewById<TextView>(R.id.onboarding_subtitle)
        val pinSection = findViewById<View>(R.id.pin_section)

        when (step) {
            0 -> { title.setText(R.string.onboarding_welcome_title); subtitle.setText(R.string.onboarding_welcome_subtitle) }
            1 -> { title.setText(R.string.onboarding_last_period_title); subtitle.setText(R.string.onboarding_last_period_subtitle) }
            2 -> { title.setText(R.string.onboarding_cycle_profile_title); subtitle.setText(R.string.onboarding_cycle_profile_subtitle) }
            3 -> { title.setText(R.string.onboarding_goals_title); subtitle.setText(R.string.onboarding_goals_subtitle) }
            4 -> { title.setText(R.string.onboarding_privacy_title); subtitle.setText(R.string.onboarding_privacy_subtitle) }
        }

        // Show PIN input only on last step
        pinSection.visibility = if (step == MAX_STEPS - 1) View.VISIBLE else View.GONE
        // Clear PIN error when entering the step
        if (step == MAX_STEPS - 1) {
            findViewById<TextInputLayout>(R.id.pin_input_layout).error = null
            findViewById<TextInputLayout>(R.id.pin_confirm_layout).error = null
        }

        val nextBtn = findViewById<Button>(R.id.next_button)
        val backBtn = findViewById<Button>(R.id.back_button)

        nextBtn.text = if (step == MAX_STEPS - 1)
            getString(R.string.onboarding_start_button)
        else
            getString(R.string.onboarding_next_button)

        backBtn.visibility = if (step == 0) View.INVISIBLE else View.VISIBLE

        nextBtn.setOnClickListener { nextStep() }
        backBtn.setOnClickListener { if (step > 0) { step--; renderStep() } }
    }

    private fun nextStep() {
        if (step < MAX_STEPS - 1) {
            step++
            renderStep()
        } else {
            if (validateAndFinish()) { /* launched async */ }
        }
    }

    private fun validateAndFinish(): Boolean {
        val pin = findViewById<TextInputEditText>(R.id.pin_input).text?.toString() ?: ""
        val confirm = findViewById<TextInputEditText>(R.id.pin_confirm_input).text?.toString() ?: ""
        val pinLayout = findViewById<TextInputLayout>(R.id.pin_input_layout)
        val confirmLayout = findViewById<TextInputLayout>(R.id.pin_confirm_layout)

        pinLayout.error = null
        confirmLayout.error = null

        if (pin.length < 6) {
            pinLayout.error = getString(R.string.onboarding_pin_too_short)
            return false
        }
        if (pin != confirm) {
            confirmLayout.error = getString(R.string.onboarding_pin_mismatch)
            return false
        }

        finishOnboarding(pin)
        return true
    }

    private fun finishOnboarding(pin: String) {
        val dbPath = VaultService.getDbPath(this)
        lifecycleScope.launch {
            try {
                val engine = LunaEngine.openVault(dbPath, pin)
                VaultService.setEngine(engine)
                // Stocker le PIN chiffré via Android Keystore pour la biométrie/reauth
                KeystoreService.storePin(this@OnboardingActivity, pin)
                getSharedPreferences("luna_prefs", Context.MODE_PRIVATE)
                    .edit().putBoolean("onboarding_done", true).apply()
                startActivity(Intent(this@OnboardingActivity, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
                finish()
            } catch (e: Exception) {
                findViewById<TextInputLayout>(R.id.pin_input_layout).error =
                    e.localizedMessage ?: getString(R.string.lock_wrong_pin)
            }
        }
    }
}
