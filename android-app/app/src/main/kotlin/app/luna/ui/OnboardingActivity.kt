package app.luna.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import app.luna.R
import app.luna.services.KeystoreService
import app.luna.services.VaultService
import kotlinx.coroutines.launch

/**
 * OnboardingActivity — 5 étapes de configuration initiale.
 * Crée le vault Rust avec le PIN choisi.
 */
class OnboardingActivity : AppCompatActivity() {

    private var step = 0
    private val MAX_STEPS = 5
    private var pin = ""
    private var pinConfirm = ""

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
        // Mise à jour barre de progression
        val progressBar = findViewById<android.widget.ProgressBar>(R.id.onboarding_progress)
        progressBar.progress = ((step + 1) * 100) / MAX_STEPS
        progressBar.contentDescription = getString(R.string.onboarding_step_a11y, step + 1, MAX_STEPS)

        val title = findViewById<TextView>(R.id.onboarding_title)
        val subtitle = findViewById<TextView>(R.id.onboarding_subtitle)

        when (step) {
            0 -> {
                title.setText(R.string.onboarding_welcome_title)
                subtitle.setText(R.string.onboarding_welcome_subtitle)
            }
            1 -> {
                title.setText(R.string.onboarding_last_period_title)
                subtitle.setText(R.string.onboarding_last_period_subtitle)
            }
            2 -> {
                title.setText(R.string.onboarding_cycle_profile_title)
                subtitle.setText(R.string.onboarding_cycle_profile_subtitle)
            }
            3 -> {
                title.setText(R.string.onboarding_goals_title)
                subtitle.setText(R.string.onboarding_goals_subtitle)
            }
            4 -> {
                title.setText(R.string.onboarding_privacy_title)
                subtitle.setText(R.string.onboarding_privacy_subtitle)
            }
        }

        // Boutons nav
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
            finishOnboarding()
        }
    }

    private fun finishOnboarding() {
        // Pour le MVP, utiliser un PIN par défaut (l'UI PIN complète est dans LockActivity)
        val dbPath = VaultService.getDbPath(this)
        lifecycleScope.launch {
            try {
                val engine = app.luna.generated.LunaEngine.openVault(dbPath, "000000")
                VaultService.setEngine(engine)
                getSharedPreferences("luna_prefs", Context.MODE_PRIVATE)
                    .edit().putBoolean("onboarding_done", true).apply()
                startActivity(Intent(this@OnboardingActivity, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
                finish()
            } catch (e: Exception) {
                // TODO: afficher erreur
            }
        }
    }
}
