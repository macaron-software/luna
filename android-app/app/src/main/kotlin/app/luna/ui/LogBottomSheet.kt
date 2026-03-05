package app.luna.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.SeekBar
import android.widget.TextView
import androidx.lifecycle.lifecycleScope
import app.luna.R
import app.luna.services.VaultService
import app.luna.generated.DailyLog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.util.UUID

/**
 * LogBottomSheet — saisie rapide du journal du jour.
 * Mood + énergie + flow + symptômes + note + BBT avancé.
 * Toutes les cibles tactiles ≥ 48dp (android:minHeight dans les layouts).
 */
class LogBottomSheet : BottomSheetDialogFragment() {

    companion object {
        const val TAG = "LogBottomSheet"
    }

    private var selectedMood: Int = 0
    private var selectedEnergy: Int = 0
    private var selectedFlow: String = "none"
    private val selectedSymptoms = mutableSetOf<String>()
    private var notes: String = ""
    private var bbt: Double? = null

    private val quickSymptoms = listOf(
        "cramps", "bloating", "fatigue", "headache",
        "breast_tenderness", "irritability", "low_mood",
        "high_energy", "motivation"
    )

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.bottom_sheet_log, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupMoodButtons(view)
        setupEnergySlider(view)
        setupFlowPicker(view)
        setupSymptomChips(view)
        setupSaveButton(view)
    }

    // ── Humeur ─────────────────────────────────────────────────────────────

    private fun setupMoodButtons(view: View) {
        val emojis = listOf("😫", "😕", "😐", "🙂", "😊")
        val container = view.findViewById<LinearLayout>(R.id.mood_container)
        emojis.forEachIndexed { i, emoji ->
            val btn = android.widget.Button(requireContext()).apply {
                text = emoji
                textSize = 28f
                setOnClickListener { selectedMood = i + 1; updateMoodSelection(container, i) }
                minWidth = dpToPx(48)
                minHeight = dpToPx(48)
                // a11y
                contentDescription = getString(
                    resources.getIdentifier("mood_level_$i", "string", requireContext().packageName)
                )
            }
            container.addView(btn)
        }
    }

    private fun updateMoodSelection(container: LinearLayout, selectedIndex: Int) {
        for (i in 0 until container.childCount) {
            val btn = container.getChildAt(i) as? android.widget.Button ?: continue
            btn.alpha = if (i == selectedIndex) 1f else 0.4f
            btn.isSelected = i == selectedIndex
        }
    }

    // ── Énergie ────────────────────────────────────────────────────────────

    private fun setupEnergySlider(view: View) {
        val slider = view.findViewById<SeekBar>(R.id.energy_slider)
        slider.max = 5
        slider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar, progress: Int, fromUser: Boolean) {
                selectedEnergy = progress
                // a11y
                sb.contentDescription = getString(R.string.energy_slider_a11y)
                sb.accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
            }
            override fun onStartTrackingTouch(sb: SeekBar) {}
            override fun onStopTrackingTouch(sb: SeekBar) {}
        })
    }

    // ── Flow ───────────────────────────────────────────────────────────────

    private fun setupFlowPicker(view: View) {
        val group = view.findViewById<RadioGroup>(R.id.flow_group)
        val flows = listOf("none", "spotting", "light", "medium", "heavy")
        flows.forEach { flow ->
            val resId = resources.getIdentifier("flow_$flow", "string", requireContext().packageName)
            RadioButton(requireContext()).apply {
                text = getString(resId)
                id = View.generateViewId()
                minHeight = dpToPx(48)
                setOnCheckedChangeListener { _, isChecked -> if (isChecked) selectedFlow = flow }
            }.also { group.addView(it) }
        }
    }

    // ── Symptômes ──────────────────────────────────────────────────────────

    private fun setupSymptomChips(view: View) {
        val container = view.findViewById<com.google.android.material.chip.ChipGroup>(R.id.symptoms_container)
        quickSymptoms.forEach { symptom ->
            val resId = resources.getIdentifier("symptom_$symptom", "string", requireContext().packageName)
            com.google.android.material.chip.Chip(requireContext()).apply {
                text = getString(resId)
                isCheckable = true
                minHeight = dpToPx(48)
                contentDescription = getString(resId)
                setOnCheckedChangeListener { _, checked ->
                    if (checked) selectedSymptoms.add(symptom) else selectedSymptoms.remove(symptom)
                }
            }.also { container.addView(it) }
        }
    }

    // ── Enregistrement ─────────────────────────────────────────────────────

    private fun setupSaveButton(view: View) {
        view.findViewById<View>(R.id.save_button).setOnClickListener {
            save()
        }
        view.findViewById<View>(R.id.cancel_button).setOnClickListener { dismiss() }
    }

    private fun save() {
        val engine = VaultService.engine ?: run { dismiss(); return }
        val today = LocalDate.now().toString()

        lifecycleScope.launch {
            try {
                val log = DailyLog(
                    id = UUID.randomUUID().toString(),
                    date = today,
                    symptoms = selectedSymptoms.toList(),
                    mood = if (selectedMood > 0) selectedMood.toUByte() else null,
                    energy = if (selectedEnergy > 0) selectedEnergy.toUByte() else null,
                    bbt = bbt,
                    lhTest = null,
                    cervicalMucus = null,
                    sexualActivity = null,
                    flow = if (selectedFlow == "none") null else selectedFlow,
                    notes = if (notes.isNotBlank()) notes else null
                )
                engine.logDay(log)
                // a11y : annoncer le succès
                view?.announceForAccessibility(getString(R.string.log_saved_a11y))
                dismiss()
            } catch (e: Exception) {
                // TODO: afficher SnackBar erreur
            }
        }
    }

    private fun dpToPx(dp: Int): Int =
        (dp * requireContext().resources.displayMetrics.density).toInt()
}
