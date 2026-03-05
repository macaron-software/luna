import XCTest

// ─────────────────────────────────────────────────────────────────────────────
// LUNA — iOS UI Tests (XCUITest)
//
// Ces tests simulent un parcours utilisateur complet dans l'UI.
// Ils requièrent un simulateur iOS 16+ avec le schème LunaApp.
//
// Exécution :
//   xcodebuild test -scheme LunaApp -destination 'platform=iOS Simulator,name=iPhone 15'
// ─────────────────────────────────────────────────────────────────────────────

final class LunaUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Réinitialise l'état pour chaque test
        app.launchArguments = ["--uitesting", "--reset-vault"]
        app.launch()
    }

    // MARK: - UJ-01 : Premier lancement → Onboarding

    /// UJ-01 : L'onboarding s'affiche au premier lancement
    func test_UJ01_firstLaunch_showsOnboarding() {
        XCTAssertTrue(
            app.staticTexts["onboarding.welcome.title"].waitForExistence(timeout: 5),
            "Onboarding title should be visible on first launch"
        )
    }

    /// UJ-01b : Compléter l'onboarding arrive sur l'écran principal
    func test_UJ01b_completeOnboarding_showsHome() {
        // Étape 1 : Bienvenue
        app.buttons["onboarding.cta.start"].tap()

        // Étape 2 : Dernières règles
        app.datePickers.firstMatch.adjust(toPickerWheelValue: "1")
        app.buttons["onboarding.cta.next"].tap()

        // Étape 3 : Profil cycle — passer
        app.buttons["onboarding.cta.next"].tap()

        // Étape 4 : Objectifs — passer
        app.buttons["onboarding.cta.next"].tap()

        // Étape 5 : PIN
        enterPIN("123456")
        app.buttons["onboarding.cta.finish"].tap()

        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 5),
            "Tab bar should appear after onboarding"
        )
    }

    // MARK: - UJ-02 : Log quotidien

    /// UJ-02 : Taper "Log today" ouvre le bottom sheet de saisie
    func test_UJ02_tapLogToday_opensLogSheet() {
        completeOnboarding()

        app.buttons["home.log_today"].tap()

        XCTAssertTrue(
            app.scrollViews["log_sheet"].waitForExistence(timeout: 3),
            "Log sheet should open after tapping Log Today"
        )
    }

    /// UJ-02b : Saisir un log et sauvegarder revient sur l'écran principal
    func test_UJ02b_saveLog_returnsToHome() {
        completeOnboarding()
        app.buttons["home.log_today"].tap()

        // Sélectionner humeur 4
        app.buttons["mood_4"].tap()
        // Sélectionner flux "light"
        app.buttons["flow_light"].tap()
        // Sauvegarder
        app.buttons["log.save"].tap()

        XCTAssertTrue(
            app.buttons["home.log_today"].waitForExistence(timeout: 3),
            "Should return to home after saving log"
        )
    }

    // MARK: - UJ-03 : Calendrier

    /// UJ-03 : Onglet Calendrier affiche une grille mensuelle
    func test_UJ03_calendarTab_showsGrid() {
        completeOnboarding()
        app.tabBars.buttons["tab.calendar"].tap()

        XCTAssertTrue(
            app.collectionViews["calendar_grid"].waitForExistence(timeout: 3),
            "Calendar grid should be visible"
        )
        // Vérifier que les 7 en-têtes de jours sont présents (L M M J V S D)
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "weekday_header").count, 7
        )
    }

    /// UJ-03b : Navigation mois précédent/suivant fonctionne
    func test_UJ03b_calendarNavigation_monthChanges() {
        completeOnboarding()
        app.tabBars.buttons["tab.calendar"].tap()

        let monthLabel = app.staticTexts["calendar_month_label"]
        let initialText = monthLabel.label

        app.buttons["calendar.previous_month"].tap()
        XCTAssertNotEqual(monthLabel.label, initialText)

        app.buttons["calendar.next_month"].tap()
        XCTAssertEqual(monthLabel.label, initialText)
    }

    // MARK: - UJ-04 : Insights

    /// UJ-04 : Onglet Insights affiche les statistiques de cycle
    func test_UJ04_insightsTab_showsStats() {
        completeOnboarding()
        app.tabBars.buttons["tab.insights"].tap()

        XCTAssertTrue(
            app.staticTexts["insights.avg_cycle_label"].waitForExistence(timeout: 3)
        )
    }

    // MARK: - UJ-05 : Verrouillage

    /// UJ-05 : Activer le verrouillage → PIN demandé au relancement
    func test_UJ05_lockEnabled_showsLockScreen_onReopen() {
        completeOnboarding()
        app.tabBars.buttons["tab.settings"].tap()
        app.switches["settings.lock_enabled"].tap() // Activer le verrouillage

        // Simuler mise en arrière-plan et retour
        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertTrue(
            app.secureTextFields["pin_input"].waitForExistence(timeout: 5),
            "PIN entry should appear when lock is enabled"
        )
    }

    // MARK: - UJ-06 : Paramètres & Export

    /// UJ-06 : Section Paramètres accessible
    func test_UJ06_settingsTab_accessible() {
        completeOnboarding()
        app.tabBars.buttons["tab.settings"].tap()

        XCTAssertTrue(app.staticTexts["settings.privacy_section"].exists)
        XCTAssertTrue(app.staticTexts["settings.notifications_section"].exists)
    }

    // MARK: - Accessibilité (a11y)

    /// A11Y-01 : Le bouton "Log today" a un accessibilityLabel
    func test_a11y_logTodayButton_hasLabel() {
        completeOnboarding()
        let btn = app.buttons["home.log_today"]
        XCTAssertFalse(btn.label.isEmpty, "Log Today button must have an accessibility label")
    }

    /// A11Y-02 : L'entrée PIN est un champ sécurisé (ne lit pas les valeurs à voix haute)
    func test_a11y_pinInput_isSecure() {
        completeOnboarding()
        app.tabBars.buttons["tab.settings"].tap()
        app.switches["settings.lock_enabled"].tap()
        app.activate()

        let pinField = app.secureTextFields["pin_input"]
        XCTAssertTrue(
            pinField.exists,
            "PIN field should be a secure text field (not readable by VoiceOver)"
        )
    }

    // MARK: - Helpers privés

    private func enterPIN(_ pin: String) {
        for digit in pin {
            app.buttons["pin_key_\(digit)"].tap()
        }
    }

    private func completeOnboarding() {
        guard app.buttons["onboarding.cta.start"].waitForExistence(timeout: 3) else { return }
        app.buttons["onboarding.cta.start"].tap()
        app.buttons["onboarding.cta.next"].tap()
        app.buttons["onboarding.cta.next"].tap()
        app.buttons["onboarding.cta.next"].tap()
        enterPIN("123456")
        app.buttons["onboarding.cta.finish"].tap()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
    }
}
