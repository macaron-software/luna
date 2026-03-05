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

        // Rappel pilule quotidien
        binding.togglePillReminder.isChecked = prefs.getBoolean("notif_pill", false)
        binding.togglePillReminder.setOnCheckedChangeListener { _, checked ->
            prefs.edit().putBoolean("notif_pill", checked).apply()
            if (checked) {
                val time = prefs.getString("pill_reminder_time", "08:00") ?: "08:00"
                val parts = time.split(":").mapNotNull { it.toIntOrNull() }
                if (parts.size == 2) {
                    app.luna.services.NotificationWorker.schedulePillReminder(
                        this@SettingsActivity, parts[0], parts[1])
                }
            } else {
                app.luna.services.NotificationWorker.cancelAll(this@SettingsActivity)
            }
        }
    }

    private fun setupButtons() {
        // Export CSV
        binding.exportCsvButton.apply {
            setOnClickListener { exportCsv() }
            contentDescription = getString(R.string.export_csv_label)
        }

        // Export backup chiffré
        binding.exportBackupButton.apply {
            setOnClickListener { exportData("backup") }
            contentDescription = getString(R.string.export_encrypted_backup_label)
        }

        // Mode de suivi
        binding.trackingModeButton.setOnClickListener {
            TrackingModeActivity.start(this)
        }

        // Panic wipe
        binding.panicWipeButton.apply {
            setOnClickListener { confirmPanicWipe() }
            contentDescription = getString(R.string.settings_delete_all_a11y)
        }
    }

    private fun exportCsv() {
        val engine = VaultService.engine ?: return
        lifecycleScope.launch {
            try {
                val cycles = engine.getCycles(100u)
                val sb = StringBuilder("cycle_id,start_date,end_date,period_length_days\n")
                for (c in cycles) {
                    sb.append("${c.id},${c.startDate},${c.endDate ?: ""},${c.periodLength ?: ""}\n")
                }
                val file = java.io.File(cacheDir, "luna_export.csv")
                file.writeText(sb.toString())
                val uri = androidx.core.content.FileProvider.getUriForFile(
                    this@SettingsActivity, "${packageName}.fileprovider", file)
                val intent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
                    type = "text/csv"
                    putExtra(android.content.Intent.EXTRA_STREAM, uri)
                    addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(android.content.Intent.createChooser(
                    intent, getString(R.string.export_csv_label)))
            } catch (e: Exception) {
                // Engine not available or no data
            }
        }
    }

    private fun exportData(format: String) {
        val engine = VaultService.engine ?: return
        lifecycleScope.launch {
            try {
                when (format) {
                    "backup" -> {
                        val backup = engine.exportEncryptedBackup("")
                        // TODO: proposer le partage via Android ShareSheet
                        @Suppress("UNUSED_VARIABLE") val ignored = backup
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
