package app.luna.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RadioButton
import android.widget.RadioGroup
import androidx.appcompat.app.AppCompatActivity
import app.luna.R

/**
 * TrackingModeActivity — choix du mode de suivi.
 * Mode stocké dans SharedPreferences (pas dans le vault).
 */
class TrackingModeActivity : AppCompatActivity() {

    companion object {
        const val PREF_TRACKING_MODE = "tracking_mode"
        const val MODE_REGULAR       = "regular"
        const val MODE_TTC           = "ttc"
        const val MODE_PREGNANT      = "pregnant"
        const val MODE_POSTPARTUM    = "postpartum"
        const val MODE_PERIMENOPAUSE = "perimenopause"

        fun start(context: Context) =
            context.startActivity(Intent(context, TrackingModeActivity::class.java))
    }

    private val modes = listOf(
        MODE_REGULAR       to R.string.tracking_mode_regular,
        MODE_TTC           to R.string.tracking_mode_ttc,
        MODE_PREGNANT      to R.string.tracking_mode_pregnant,
        MODE_POSTPARTUM    to R.string.tracking_mode_postpartum,
        MODE_PERIMENOPAUSE to R.string.tracking_mode_perimenopause,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val radioGroup = RadioGroup(this).apply {
            orientation = RadioGroup.VERTICAL
            setPadding(48, 48, 48, 48)
        }

        modes.forEach { (mode, labelRes) ->
            val rb = RadioButton(this).apply {
                id = View.generateViewId()
                text = getString(labelRes)
                tag = mode
                minHeight = 44.dpToPx()
                textSize = 16f
            }
            radioGroup.addView(rb)
        }

        setContentView(radioGroup)
        supportActionBar?.apply {
            title = getString(R.string.settings_tracking_mode)
            setDisplayHomeAsUpEnabled(true)
        }

        // Restore saved mode
        val prefs = getSharedPreferences("luna_prefs", Context.MODE_PRIVATE)
        val current = prefs.getString(PREF_TRACKING_MODE, MODE_REGULAR)
        for (i in 0 until radioGroup.childCount) {
            val rb = radioGroup.getChildAt(i) as? RadioButton ?: continue
            if (rb.tag == current) {
                radioGroup.check(rb.id)
                break
            }
        }

        radioGroup.setOnCheckedChangeListener { group, checkedId ->
            val rb = group.findViewById<RadioButton>(checkedId)
            val mode = rb?.tag as? String ?: return@setOnCheckedChangeListener
            prefs.edit().putString(PREF_TRACKING_MODE, mode).apply()
        }
    }

    private fun Int.dpToPx(): Int = (this * resources.displayMetrics.density).toInt()

    override fun onSupportNavigateUp(): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
