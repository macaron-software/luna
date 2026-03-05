package app.luna.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.luna.services.VaultService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate

class HomeViewModel : ViewModel() {

    data class HomeUiState(
        val cycleDay: Int = 1,
        val daysUntilNextPeriod: Int = 0,
        val phaseName: String = "",
        val insight: String? = null,
        val phaseChanged: Boolean = false,
    )

    private val _uiState = MutableStateFlow<HomeUiState?>(null)
    val uiState: StateFlow<HomeUiState?> = _uiState

    private var lastPhase: String = ""

    fun load() {
        val engine = VaultService.engine ?: return
        viewModelScope.launch {
            try {
                val prediction = engine.predictNext()
                val cycles = engine.getCycles(1u)
                val today = LocalDate.now()
                val nextDate = prediction.nextPeriodStart
                val daysLeft = calculateDaysLeft(nextDate, today.toString())

                // Compute current cycle day from latest cycle start
                val cycleDay = cycles.firstOrNull()?.let { cycle ->
                    try {
                        val start = LocalDate.parse(cycle.startDate)
                        maxOf(1, java.time.temporal.ChronoUnit.DAYS.between(start, today).toInt() + 1)
                    } catch (e: Exception) { 1 }
                } ?: 1

                // Derive phase from algorithm hint
                val phase = prediction.algorithm
                val phaseChanged = phase != lastPhase && lastPhase.isNotEmpty()
                lastPhase = phase
                _uiState.value = HomeUiState(
                    cycleDay = cycleDay,
                    daysUntilNextPeriod = daysLeft,
                    phaseName = phase,
                    insight = null, // TODO: générer un insight depuis l'historique
                    phaseChanged = phaseChanged,
                )
            } catch (e: Exception) {
                _uiState.value = HomeUiState()
            }
        }
    }

    private fun calculateDaysLeft(nextPeriodDate: String, today: String): Int {
        return try {
            val next = LocalDate.parse(nextPeriodDate)
            val now = LocalDate.parse(today)
            maxOf(0, java.time.temporal.ChronoUnit.DAYS.between(now, next).toInt())
        } catch (e: Exception) { 0 }
    }
}
