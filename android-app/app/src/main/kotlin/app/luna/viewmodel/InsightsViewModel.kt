package app.luna.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.luna.services.VaultService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class InsightsViewModel : ViewModel() {

    data class InsightsStats(
        val avgCycleLength: Double?,
        val avgPeriodLength: Double?,
        val topSymptoms: List<Pair<String, Double>>,
    )

    private val _stats = MutableStateFlow<InsightsStats?>(null)
    val stats: StateFlow<InsightsStats?> = _stats

    fun load() {
        val engine = VaultService.engine ?: return
        viewModelScope.launch {
            try {
                val summary = engine.getCycleSummary()
                _stats.value = InsightsStats(
                    avgCycleLength = summary.avgCycleLength,
                    avgPeriodLength = summary.avgPeriodLength,
                    topSymptoms = emptyList(), // TODO: agréger depuis les logs
                )
            } catch (e: Exception) {
                _stats.value = InsightsStats(null, null, emptyList())
            }
        }
    }
}
