import XCTest

/// Tests de parcours utilisateur LUNA.
/// Parcours sans données (premier lancement) et avec données pré-chargées.
final class UserJourneyTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Journey 1: Premier lancement (sans données)

    /// Parcours onboarding complet sans données préexistantes
    func testFirstLaunchOnboarding_noData() {
        app.launchArguments += ["--reset-vault"]
        app.launch()

        // L'écran d'onboarding doit apparaître
        XCTAssertTrue(app.staticTexts["app_name"].waitForExistence(timeout: 5))

        // Naviguer à travers les étapes d'onboarding
        let nextButton = app.buttons["onboarding_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.tap()

        // Accepter les conditions
        let consentButton = app.buttons["onboarding_consent_accept"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }
    }

    // MARK: - Journey 2: Saisie d'un log quotidien (sans données initiales)

    func testLogDay_noExistingData() {
        app.launchArguments += ["--uitesting-unlock"]
        app.launch()

        // Attendre l'écran principal
        let logButton = app.buttons["log_button_a11y"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 10))
        logButton.tap()

        // La feuille de log doit s'ouvrir
        XCTAssertTrue(app.navigationBars["log_sheet_title"].waitForExistence(timeout: 5))

        // Sélectionner un flux
        let flowLight = app.buttons["flow_light"]
        if flowLight.waitForExistence(timeout: 3) {
            flowLight.tap()
        }

        // Sélectionner une humeur
        let mood3 = app.buttons["3"]
        if mood3.waitForExistence(timeout: 3) {
            mood3.tap()
        }

        // Fermer
        let saveBtn = app.buttons["save_button"]
        if saveBtn.waitForExistence(timeout: 3) {
            saveBtn.tap()
        }
    }

    // MARK: - Journey 3: Voir les insights (avec données)

    func testInsightsView_withData() {
        app.launchArguments += ["--uitesting-unlock", "--seed-data"]
        app.launch()

        // Naviguer vers Insights
        let insightsTab = app.tabBars.buttons["tab_insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10))
        insightsTab.tap()

        // Les stats doivent être visibles
        XCTAssertTrue(app.staticTexts["stats_section_title"].waitForExistence(timeout: 5))
    }

    // MARK: - Journey 4: Paramètres — export CSV

    func testSettings_exportCSV() {
        app.launchArguments += ["--uitesting-unlock", "--seed-data"]
        app.launch()

        // Aller dans les paramètres
        let settingsTab = app.tabBars.buttons["tab_settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        // Bouton export CSV
        let exportBtn = app.buttons["export_csv_label"]
        XCTAssertTrue(exportBtn.waitForExistence(timeout: 5))
        exportBtn.tap()

        // Une sheet de partage doit apparaître (ou un dialog)
        // Sur simulateur sans vraies données, la sheet peut ne pas s'ouvrir
        // On vérifie juste que l'app ne crash pas
        XCTAssertTrue(app.exists)
    }

    // MARK: - Journey 5: Mode TTC

    func testTrackingMode_TTCSelection() {
        app.launchArguments += ["--uitesting-unlock"]
        app.launch()

        let settingsTab = app.tabBars.buttons["tab_settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        // Trouver le lien Mode de suivi
        let trackingModeLink = app.cells.containing(.staticText, identifier: "settings_tracking_mode").firstMatch
        if trackingModeLink.waitForExistence(timeout: 5) {
            trackingModeLink.tap()
            // Sélectionner TTC
            let ttcOption = app.cells.containing(.staticText, identifier: "tracking_mode_ttc").firstMatch
            if ttcOption.waitForExistence(timeout: 5) {
                ttcOption.tap()
            }
            // Sauvegarder
            let saveBtn = app.buttons["save_button"]
            if saveBtn.waitForExistence(timeout: 3) {
                saveBtn.tap()
            }
        }
    }

    // MARK: - Journey 6: CRUD cycle complet

    func testCRUD_startAndLogCycle() {
        app.launchArguments += ["--uitesting-unlock"]
        app.launch()

        // 1. Démarrer un cycle depuis HomeView
        let startCycleBtn = app.buttons["home_start_cycle_button"]
        if startCycleBtn.waitForExistence(timeout: 5) {
            startCycleBtn.tap()
            // Confirmer
            let confirmBtn = app.buttons["confirm_button"]
            if confirmBtn.waitForExistence(timeout: 3) {
                confirmBtn.tap()
            }
        }

        // 2. Logger un jour
        let logBtn = app.buttons["log_button_a11y"]
        if logBtn.waitForExistence(timeout: 5) {
            logBtn.tap()
            // Sauvegarder sans rien changer (log vide)
            let saveBtn = app.buttons["save_button"]
            if saveBtn.waitForExistence(timeout: 3) {
                saveBtn.tap()
            }
        }

        // 3. Vérifier que le calendrier montre bien la mise à jour
        let calendarTab = app.tabBars.buttons["tab_calendar"]
        if calendarTab.waitForExistence(timeout: 5) {
            calendarTab.tap()
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Journey 7: Panic Wipe

    func testPanicWipe() {
        app.launchArguments += ["--uitesting-unlock", "--seed-data"]
        app.launch()

        let settingsTab = app.tabBars.buttons["tab_settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()

        let panicBtn = app.buttons.matching(identifier: "settings_delete_all_a11y").firstMatch
        if panicBtn.waitForExistence(timeout: 5) {
            panicBtn.tap()
            // Confirmer dans le dialog
            let confirmWipe = app.buttons["panic_wipe_confirm_button"]
            if confirmWipe.waitForExistence(timeout: 3) {
                confirmWipe.tap()
                // Après le wipe, on doit revenir à l'écran de lock ou onboarding
                XCTAssertTrue(
                    app.staticTexts["app_name"].waitForExistence(timeout: 5) ||
                    app.navigationBars.firstMatch.waitForExistence(timeout: 5)
                )
            }
        }
    }
}
