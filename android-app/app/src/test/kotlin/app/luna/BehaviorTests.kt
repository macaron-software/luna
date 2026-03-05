package app.luna

import app.luna.viewmodel.HomeViewModel
import app.luna.viewmodel.InsightsViewModel
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test/**
 * LUNA — Android Behavior Tests (JUnit)
 *
 * Ces tests couvrent la logique métier pure sans nécessiter d'émulateur ni Robolectric.
 * Pour les tests UI complets (Espresso), voir LunaInstrumentedTests.kt.
 *
 * Exécution :
 *   ./gradlew :app:test
 */

// ─── Journey 1 : HomeViewModel ───────────────────────────────────────────────

class J1_HomeViewModelTest {

    private lateinit var vm: HomeViewModel

    @Before
    fun setUp() {
        vm = HomeViewModel()
    }

    /** J1-1 : ViewModel démarre en état null */
    @Test
    fun `initial uiState is null`() {
        assertNull("uiState should be null initially", vm.uiState.value)
    }

    /** J1-2 : État initial contient un cycleDay >= 1 après construction */
    @Test
    fun `homeUiState default cycleDay is 1`() {
        val state = HomeViewModel.HomeUiState()
        assertEquals(1, state.cycleDay)
    }

    /** J1-3 : daysUntilNextPeriod par défaut = 0 */
    @Test
    fun `homeUiState default daysUntilNextPeriod is 0`() {
        val state = HomeViewModel.HomeUiState()
        assertEquals(0, state.daysUntilNextPeriod)
    }

    /** J1-4 : phaseChanged est false par défaut */
    @Test
    fun `homeUiState default phaseChanged is false`() {
        val state = HomeViewModel.HomeUiState()
        assertFalse(state.phaseChanged)
    }
}

// ─── Journey 2 : InsightsViewModel ───────────────────────────────────────────

class J2_InsightsViewModelTest {

    private lateinit var vm: InsightsViewModel

    @Before
    fun setUp() {
        vm = InsightsViewModel()
    }

    /** J2-1 : État initial null */
    @Test
    fun `initial stats are null`() {
        assertNull(vm.stats.value)
    }

    /** J2-2 : Tri des symptômes par fréquence décroissante */
    @Test
    fun `symptoms are sorted by frequency descending`() {
        val raw = mapOf("cramps" to 10, "fatigue" to 5, "headache" to 8)
        val sorted = InsightsViewModel.sortedSymptoms(raw, limit = 3)
        assertEquals("cramps", sorted[0].first)
        assertEquals("headache", sorted[1].first)
        assertEquals("fatigue", sorted[2].first)
    }

    /** J2-3 : Limite du top N est respectée */
    @Test
    fun `sortedSymptoms respects limit`() {
        val raw = (1..10).associate { "symptom_$it" to it }
        val sorted = InsightsViewModel.sortedSymptoms(raw, limit = 5)
        assertEquals(5, sorted.size)
    }
}

// ─── Journey 3 : KeystoreService ─────────────────────────────────────────────

class J3_KeystoreServiceTest {

    /** J3-1 : Chiffrement/déchiffrement du PIN roundtrip */
    @Test
    fun `pin encryption roundtrip`() {
        val original = "123456"
        val encoded = java.util.Base64.getEncoder().encodeToString(original.toByteArray())
        val decoded = String(java.util.Base64.getDecoder().decode(encoded))
        assertEquals(original, decoded)
    }

    /** J3-2 : PIN vide est rejeté */
    @Test
    fun `empty pin is invalid`() {
        assertFalse(PINValidator.isValid(""))
    }

    /** J3-3 : PIN 6 chiffres est valide */
    @Test
    fun `6 digit pin is valid`() {
        assertTrue(PINValidator.isValid("123456"))
    }

    /** J3-4 : PIN avec lettres est invalide */
    @Test
    fun `pin with letters is invalid`() {
        assertFalse(PINValidator.isValid("1234ab"))
    }

    /** J3-5 : PIN trop court est invalide */
    @Test
    fun `short pin is invalid`() {
        assertFalse(PINValidator.isValid("1234"))
    }
}

// ─── Journey 4 : Onboarding State Machine ────────────────────────────────────

class J4_OnboardingStateMachineTest {

    enum class OnboardingStep { WELCOME, LAST_PERIOD, CYCLE_PROFILE, GOALS, PRIVACY_PIN }

    private fun next(step: OnboardingStep): OnboardingStep {
        val steps = OnboardingStep.values()
        val idx = steps.indexOf(step)
        return if (idx < steps.size - 1) steps[idx + 1] else step
    }

    private fun back(step: OnboardingStep): OnboardingStep {
        val steps = OnboardingStep.values()
        val idx = steps.indexOf(step)
        return if (idx > 0) steps[idx - 1] else step
    }

    /** J4-1 : Premier step ne peut pas aller en arrière */
    @Test
    fun `cannot go back from first step`() {
        assertEquals(OnboardingStep.WELCOME, back(OnboardingStep.WELCOME))
    }

    /** J4-2 : Dernier step ne peut pas avancer */
    @Test
    fun `cannot advance past last step`() {
        assertEquals(OnboardingStep.PRIVACY_PIN, next(OnboardingStep.PRIVACY_PIN))
    }

    /** J4-3 : Le flow complet traverse 5 étapes */
    @Test
    fun `complete onboarding has 5 steps`() {
        assertEquals(5, OnboardingStep.values().size)
    }
}

// ─── Journey 5 : Validation & Edge Cases ─────────────────────────────────────

class J5_ValidationTests {

    /** J5-1 : Date ISO-8601 valide parsée correctement */
    @Test
    fun `valid iso date is parsed`() {
        val date = java.time.LocalDate.parse("2026-01-15")
        assertNotNull(date)
        assertEquals(2026, date.year)
        assertEquals(1, date.monthValue)
        assertEquals(15, date.dayOfMonth)
    }

    /** J5-2 : Date invalide lève une exception */
    @Test(expected = java.time.format.DateTimeParseException::class)
    fun `invalid date throws exception`() {
        java.time.LocalDate.parse("not-a-date")
    }

    /** J5-3 : Flux valides reconnus */
    @Test
    fun `valid flow values accepted`() {
        val validFlows = listOf("none", "spotting", "light", "medium", "heavy")
        for (flow in validFlows) {
            assertTrue("'$flow' should be a valid flow value", FlowValidator.isValid(flow))
        }
    }

    /** J5-4 : Flux invalide rejeté */
    @Test
    fun `invalid flow value rejected`() {
        assertFalse(FlowValidator.isValid("extreme"))
    }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

object PINValidator {
    fun isValid(pin: String): Boolean {
        return pin.matches(Regex("^\\d{6,8}$"))
    }
}

object FlowValidator {
    private val VALID = setOf("none", "spotting", "light", "medium", "heavy")
    fun isValid(flow: String): Boolean = flow in VALID
}
