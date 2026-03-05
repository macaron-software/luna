package app.luna.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.CompoundButton
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import app.luna.R
import app.luna.databinding.ActivitySettingsBinding
import app.luna.services.VaultService
import kotlinx.coroutines.launch

/**
 * SettingsActivity — paramètres vie privée, notifications, export, panic wipe.
 * Accessible depuis SettingsFragment via navigation.
 */
class SettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySettingsBinding

    companion object {
        fun start(context: Context) =
            context.startActivity(Intent(context, SettingsActivity::class.java))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        supportActionBar?.apply {
            title = getString(R.string.tab_settings)
            setDisplayHomeAsUpEnabled(true)
        }

        setupToggles()
        setupButtons()
    }

    private fun setupToggles() {
        val prefs = getSharedPreferences("luna_prefs", Context.MODE_PRIVATE)

        // Notifications journalières
        binding.toggleDailyNotif.isChecked = prefs.getBoolean("notif_daily", true)
        binding.toggleDailyNotif.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean("notif_daily", checked).apply()
        }

        // Rappel règles
        binding.togglePeriodReminder.isChecked = prefs.getBoolean("notif_period", true)
        binding.togglePeriodReminder.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean("notif_period", checked).apply()
        }

        // Fenêtre fertile
        binding.toggleFertileWindow.isChecked = prefs.getBoolean("notif_fertile", false)
        binding.toggleFertileWindow.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean("notif_fertile", checked).apply()
        }
    }

    private fun setupButtons() {
        // Export CSV
        binding.exportCsvButton.apply {
            setOnClickListener { exportData("csv") }
            contentDescription = getString(R.string.export_csv_label)
        }

        // Export backup chiffré
        binding.exportBackupButton.apply {
            setOnClickListener { exportData("backup") }
            contentDescription = getString(R.string.export_encrypted_backup_label)
        }

        // Panic wipe
        binding.panicWipeButton.apply {
            setOnClickListener { confirmPanicWipe() }
            contentDescription = getString(R.string.settings_delete_all_a11y)
        }
    }

    private fun exportData(format: String) {
        val engine = VaultService.engine ?: return
        lifecycleScope.launch {
            try {
                when (format) {
                    "backup" -> {
                        val backup = engine.exportEncryptedBackup()
                        // TODO: proposer le partage via Android ShareSheet
                        _ = backup
                    }
                }
            } catch (e: Exception) {
                // TODO: SnackBar erreur
            }
        }
    }

    private fun confirmPanicWipe() {
        androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle(getString(R.string.panic_wipe_confirm_title))
            .setMessage(getString(R.string.panic_wipe_confirm_message))
            .setPositiveButton(getString(R.string.panic_wipe_confirm_button)) { _, _ ->
                panicWipe()
            }
            .setNegativeButton(getString(R.string.cancel_button), null)
            .show()
    }

    private fun panicWipe() {
        val engine = VaultService.engine ?: return
        lifecycleScope.launch {
            try {
                engine.panicWipe()
            } catch (e: Exception) {
                // Erreur attendue = WipedSuccessfully
            }
            VaultService.lock()
            binding.root.announceForAccessibility(getString(R.string.panic_wipe_done_a11y))
            LockActivity.start(this@SettingsActivity)
            finishAffinity()
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
