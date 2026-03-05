package app.luna.ui

import android.os.Bundle
import android.content.Intent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import app.luna.R
import app.luna.databinding.FragmentHomeBinding
import app.luna.viewmodel.HomeViewModel
import kotlinx.coroutines.launch

/**
 * HomeFragment — Écran "Aujourd'hui"
 * Affiche : jauge cycle, phase actuelle, CTA log, mini-calendrier 7j, insight.
 */
class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!
    private val viewModel: HomeViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupAccessibility()
        setupLogButton()
        observeViewModel()

        viewModel.load()
    }

    // ── Setup a11y ─────────────────────────────────────────────────────────

    private fun setupAccessibility() {
        // Badge "données locales" — rôle informatif
        binding.privacyBadge.contentDescription = getString(R.string.privacy_badge_a11y)
        binding.privacyBadge.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES

        // Widget cycle — description composée
        binding.cycleWidget.accessibilityDelegate = object : View.AccessibilityDelegate() {
            override fun onInitializeAccessibilityNodeInfo(
                host: View, info: android.view.accessibility.AccessibilityNodeInfo
            ) {
                super.onInitializeAccessibilityNodeInfo(host, info)
                viewModel.uiState.value?.let { state ->
                    info.contentDescription = getString(
                        R.string.cycle_progress_a11y,
                        state.cycleDay,
                        state.daysUntilNextPeriod
                    )
                }
            }
        }
    }

    // ── Bouton Log ─────────────────────────────────────────────────────────

    private fun setupLogButton() {
        binding.logTodayButton.apply {
            setOnClickListener {
                LogBottomSheet().show(parentFragmentManager, LogBottomSheet.TAG)
            }
            // a11y: taille cible ≥ 48dp garantie par le layout XML
            contentDescription = getString(R.string.log_today_button)
        }
    }

    // ── Observation ────────────────────────────────────────────────────────

    private fun observeViewModel() {
        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.uiState.collect { state ->
                    if (state != null) {
                        renderState(state)
                    }
                }
            }
        }
    }

    private fun renderState(state: HomeViewModel.HomeUiState) {
        // Jour du cycle
        binding.cycleDayLabel.text = getString(R.string.cycle_day_label, state.cycleDay)
        binding.nextPeriodLabel.text = resources.getQuantityString(
            R.plurals.days_until_period, state.daysUntilNextPeriod, state.daysUntilNextPeriod
        )

        // Phase
        binding.phaseLabel.text = state.phaseName

        // Insight
        state.insight?.let {
            binding.insightCard.visibility = View.VISIBLE
            binding.insightText.text = it
        } ?: run {
            binding.insightCard.visibility = View.GONE
        }

        // Tracking mode banners
        val trackingMode = requireContext()
            .getSharedPreferences("luna_prefs", android.content.Context.MODE_PRIVATE)
            .getString("tracking_mode", "regular") ?: "regular"

        binding.perimenopauseBanner.visibility =
            if (trackingMode == TrackingModeActivity.MODE_PERIMENOPAUSE) View.VISIBLE else View.GONE
        binding.ttcBanner.visibility =
            if (trackingMode == TrackingModeActivity.MODE_TTC) View.VISIBLE else View.GONE

        binding.perimenopauseBannerArrow.setOnClickListener {
            startActivity(Intent(requireContext(), TrackingModeActivity::class.java))
        }

        // a11y : annoncer le changement de phase si nouveau
        if (state.phaseChanged) {
            binding.root.announceForAccessibility(
                getString(R.string.phase_changed_a11y, state.phaseName)
            )
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
