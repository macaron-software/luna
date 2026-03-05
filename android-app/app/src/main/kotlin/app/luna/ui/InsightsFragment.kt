package app.luna.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import app.luna.databinding.FragmentInsightsBinding
import app.luna.R
import app.luna.viewmodel.InsightsViewModel
import kotlinx.coroutines.launch

/**
 * InsightsFragment — statistiques cycle, fréquence symptômes, fiches éducatives.
 */
class InsightsFragment : Fragment() {

    private var _binding: FragmentInsightsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: InsightsViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentInsightsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        observeViewModel()
        setupCharts()
        viewModel.load()
    }

    private fun observeViewModel() {
        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.stats.collect { stats ->
                    stats?.let { renderStats(it) }
                }
            }
        }
    }

    private fun renderStats(stats: InsightsViewModel.InsightsStats) {
        // Durée moyenne cycle
        binding.avgCycleValue.text = stats.avgCycleLength
            ?.let { "%.1f".format(it) } ?: "--"
        binding.avgCycleValue.contentDescription =
            "Durée moyenne du cycle : ${binding.avgCycleValue.text} jours"

        // Durée moyenne règles
        binding.avgPeriodValue.text = stats.avgPeriodLength
            ?.let { "%.1f".format(it) } ?: "--"

        // Symptômes top 5 — mise à jour des barres
        // TODO: Lier à des vues SymptomBarView individuelles dans le layout
        @Suppress("UNUSED_VARIABLE")
        val topSymptoms = stats.topSymptoms
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun setupCharts() {
        val container = binding.chartsContainer

        val cycleChart = CycleChartView(requireContext()).apply {
            chartType = CycleChartView.ChartType.BAR
            dataPoints = listOf(
                "C1" to 28f, "C2" to 30f, "C3" to 27f,
                "C4" to 29f, "C5" to 28f, "C6" to 31f
            )
            yMin = 20f; yMax = 40f
            contentDescription = getString(R.string.charts_cycle_lengths_a11y)
        }

        val bbtChart = CycleChartView(requireContext()).apply {
            chartType = CycleChartView.ChartType.LINE
            dataPoints = (1..14).map { "J$it" to (36.5f + if (it > 7) 0.3f else 0f) }
            yMin = 36.0f; yMax = 37.5f
            contentDescription = getString(R.string.charts_bbt_a11y)
        }

        container.addView(cycleChart)
        container.addView(bbtChart)
    }
}
