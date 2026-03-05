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
                val today = LocalDate.now().toString()
                val daysLeft = calculateDaysLeft(prediction.nextPeriodDate, today)
                val phase = prediction.currentPhase
                val phaseChanged = phase != lastPhase && lastPhase.isNotEmpty()
                lastPhase = phase
                _uiState.value = HomeUiState(
                    cycleDay = prediction.currentCycleDay.toInt(),
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
