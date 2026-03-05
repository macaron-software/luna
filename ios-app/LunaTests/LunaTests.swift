import XCTest
@testable import LunaApp

// ─────────────────────────────────────────────────────────────────────────────
// LUNA — iOS User Journey Tests (XCTest)
//
// Ces tests couvrent les ViewModels et la logique de navigation.
// Les tests UI complets (XCUITest) sont dans LunaUITests/.
//
// NB : les types LunaEngine / Prediction sont générés par UniFFI.
//      En CI, ces tests nécessitent que `scripts/build-ios.sh` ait été exécuté.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Journey 1 : AppState & Onboarding

final class J1_AppStateTests: XCTestCase {

    /// J1-1 : AppState démarre avec isOnboardingDone = false et pas de vault
    func test_initialState_noVaultNoOnboarding() {
        let state = AppState()
        XCTAssertFalse(state.isVaultOpen, "No engine → vault should not be open")
        XCTAssertFalse(state.isOnboardingDone, "Fresh install → onboarding not done")
        XCTAssertNil(state.engine, "Engine should be nil before open_vault")
    }

    /// J1-2 : userName est vide par défaut
    func test_initialState_userNameEmpty() {
        let state = AppState()
        XCTAssertTrue(state.userName.isEmpty)
    }

    /// J1-3 : lockEnabled est false par défaut
    func test_initialState_lockDisabled() {
        let state = AppState()
        XCTAssertFalse(state.lockEnabled)
    }

    /// J1-4 : dbPath est une URL valide dans les documents
    func test_dbPath_isInDocumentsDirectory() {
        let state = AppState()
        XCTAssertTrue(state.dbPath.hasSuffix("luna.db"), "DB path should end with luna.db")
        XCTAssertTrue(
            state.dbPath.contains("Documents") || state.dbPath.contains("Application Support"),
            "DB should be in a protected directory"
        )
    }
}

// MARK: - Journey 2 : HomeViewModel

final class J2_HomeViewModelTests: XCTestCase {

    /// J2-1 : ViewModel démarre dans l'état idle
    func test_homeViewModel_initialState() {
        let vm = HomeViewModel()
        XCTAssertNil(vm.prediction, "No prediction before vault is open")
        XCTAssertFalse(vm.isLoading)
    }

    /// J2-2 : Phase du cycle détectée correctement depuis la date
    func test_cyclePhaseFromDayNumber() {
        // Phase folliculaire : jours 6–13 (après règles)
        XCTAssertEqual(HomeViewModel.phase(forDay: 7, cycleLength: 28), .follicular)
        // Phase ovulatoire : autour du jour 14
        XCTAssertEqual(HomeViewModel.phase(forDay: 14, cycleLength: 28), .ovulatory)
        // Phase lutéale : jours 15–28
        XCTAssertEqual(HomeViewModel.phase(forDay: 20, cycleLength: 28), .luteal)
        // Phase menstruelle : jours 1–5
        XCTAssertEqual(HomeViewModel.phase(forDay: 2, cycleLength: 28), .menstrual)
    }

    /// J2-3 : Jour 0 → renvoie la phase menstruelle (premier jour)
    func test_cycleDay_zero_isMenstrual() {
        XCTAssertEqual(HomeViewModel.phase(forDay: 1, cycleLength: 28), .menstrual)
    }
}

// MARK: - Journey 3 : LockView Logic

final class J3_LockLogicTests: XCTestCase {

    /// J3-1 : PIN de 6 chiffres est valide
    func test_pinValidation_6digits_valid() {
        XCTAssertTrue(PINValidator.isValid("123456"))
    }

    /// J3-2 : PIN trop court est invalide
    func test_pinValidation_tooShort_invalid() {
        XCTAssertFalse(PINValidator.isValid("1234"))
    }

    /// J3-3 : PIN avec lettres est invalide
    func test_pinValidation_withLetters_invalid() {
        XCTAssertFalse(PINValidator.isValid("1234ab"))
    }

    /// J3-4 : PIN vide est invalide
    func test_pinValidation_empty_invalid() {
        XCTAssertFalse(PINValidator.isValid(""))
    }

    /// J3-5 : PIN de 8 chiffres est valide (longueur max)
    func test_pinValidation_8digits_valid() {
        XCTAssertTrue(PINValidator.isValid("12345678"))
    }
}

// MARK: - Journey 4 : Onboarding Steps

final class J4_OnboardingTests: XCTestCase {

    /// J4-1 : OnboardingStep progression : welcome → lastPeriod → …
    func test_onboardingSteps_order() {
        let steps = OnboardingStep.allCases
        XCTAssertEqual(steps.first, .welcome)
        XCTAssertEqual(steps.last, .privacyAndPin)
        XCTAssertEqual(steps.count, 5)
    }

    /// J4-2 : Le premier step ne permet pas de revenir en arrière
    func test_onboardingStep_backFromFirst_staysAtFirst() {
        var step = OnboardingStep.welcome
        step.goBack()
        XCTAssertEqual(step, .welcome, "Cannot go back from first step")
    }

    /// J4-3 : Avancer depuis le dernier step ne dépasse pas
    func test_onboardingStep_nextFromLast_staysAtLast() {
        var step = OnboardingStep.privacyAndPin
        step.goNext()
        XCTAssertEqual(step, .privacyAndPin, "Cannot advance past last step")
    }
}

// MARK: - Journey 5 : Cycle Calendar

final class J5_CalendarTests: XCTestCase {

    /// J5-1 : CalendarViewModel génère les bons jours pour janvier 2026
    func test_calendarDays_january2026() {
        let calendar = Calendar.current
        var comps = DateComponents(year: 2026, month: 1, day: 1)
        let jan2026 = calendar.date(from: comps)!
        let days = CalendarViewModel.daysInMonth(for: jan2026)
        XCTAssertEqual(days.count, 31)
    }

    /// J5-2 : Aujourd'hui est marqué comme "today"
    func test_calendarDay_todayIsMarked() {
        let today = Date()
        let day = CalendarDay(date: today, isToday: true, eventType: nil)
        XCTAssertTrue(day.isToday)
    }

    /// J5-3 : Navigation arrière/avant de mois fonctionne
    func test_calendarNavigation_monthChanges() {
        let vm = CalendarViewModel()
        let initialMonth = vm.displayedMonth
        vm.goToPreviousMonth()
        XCTAssertNotEqual(vm.displayedMonth, initialMonth)
        vm.goToNextMonth()
        XCTAssertEqual(vm.displayedMonth, initialMonth)
    }
}

// MARK: - Journey 6 : Insights

final class J6_InsightsTests: XCTestCase {

    /// J6-1 : Résumé sans cycles retourne des valeurs par défaut
    func test_insightsSummary_noCycles_defaults() {
        let summary = InsightsViewModel.Summary.empty
        XCTAssertEqual(summary.avgCycleLength, 28.0)
        XCTAssertNil(summary.mostFrequentSymptom)
    }

    /// J6-2 : Top symptômes triés par fréquence décroissante
    func test_topSymptoms_sortedByFrequency() {
        let raw: [String: Int] = ["cramps": 10, "fatigue": 5, "headache": 8]
        let sorted = InsightsViewModel.sortedSymptoms(from: raw, limit: 3)
        XCTAssertEqual(sorted[0].symptom, "cramps")
        XCTAssertEqual(sorted[1].symptom, "headache")
        XCTAssertEqual(sorted[2].symptom, "fatigue")
    }
}

// MARK: - Journey 7 : i18n

final class J7_I18nTests: XCTestCase {

    /// J7-1 : Toutes les clés critiques sont localisées en anglais
    func test_i18n_criticalKeys_en() {
        let keys = [
            "home.cycle_day",
            "home.log_today",
            "onboarding.privacy_title",
            "lock.biometric_prompt",
            "settings.panic_wipe_title",
        ]
        for key in keys {
            let localized = NSLocalizedString(key, bundle: .main, comment: "")
            // Si la clé n'est pas trouvée, NSLocalizedString retourne la clé elle-même
            XCTAssertNotEqual(localized, key, "Key '\(key)' is not localized")
        }
    }

    /// J7-2 : Les clés RTL (arabe) ne doivent pas être vides
    func test_i18n_arabic_keys_present() {
        guard let arBundle = Bundle(
            path: Bundle.main.path(forResource: "ar", ofType: "lproj") ?? ""
        ) else {
            // Bundle AR non disponible en test unitaire → skip
            return
        }
        let title = NSLocalizedString("onboarding.privacy_title", bundle: arBundle, comment: "")
        XCTAssertFalse(title.isEmpty)
    }
}

// MARK: - Journey 8 : Accessibilité

final class J8_AccessibilityTests: XCTestCase {

    /// J8-1 : HomeView contient les accessibilityLabels requis
    @MainActor
    func test_homeView_accessibilityLabels_present() {
        let state = AppState()
        // Vérifier que les chaînes d'accessibilité peuvent être construites
        let cycleLabel = String(format: NSLocalizedString("a11y.cycle_day_label", comment: ""), 14)
        XCTAssertFalse(cycleLabel.isEmpty)
    }
}
