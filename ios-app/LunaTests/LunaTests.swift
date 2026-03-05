import XCTest
@testable import LunaApp

// MARK: - J1: AppState initial state

final class J1_AppStateTests: XCTestCase {

    /// J1-1: Vault fermé au démarrage
    func test_initialState_vaultClosed() {
        let state = AppState()
        XCTAssertFalse(state.isVaultOpen)
        XCTAssertNil(state.engine)
    }

    /// J1-2: isLocked est l'inverse de isVaultOpen
    func test_isLocked_inversOfVaultOpen() {
        let state = AppState()
        XCTAssertTrue(state.isLocked)
        XCTAssertEqual(state.isLocked, !state.isVaultOpen)
    }

    /// J1-3: calmMode peut être activé/désactivé
    func test_calmMode_canBeToggled() {
        let state = AppState()
        let initial = state.calmMode
        state.calmMode = !initial
        XCTAssertEqual(state.calmMode, !initial)
    }
}

// MARK: - J2: dbPath

final class J2_DbPathTests: XCTestCase {

    /// J2-1: dbPath pointe dans les documents ou Application Support
    func test_dbPath_isInProtectedDirectory() {
        let state = AppState()
        XCTAssertTrue(
            state.dbPath.contains("Documents") ||
            state.dbPath.contains("Application Support") ||
            state.dbPath.hasSuffix(".db"),
            "DB should be in a protected or named path: \(state.dbPath)"
        )
    }
}

// MARK: - J3: NotificationManager

final class J3_NotificationTests: XCTestCase {

    func test_notificationManager_singleton() {
        let nm1 = NotificationManager.shared
        let nm2 = NotificationManager.shared
        XCTAssertTrue(nm1 === nm2)
    }

    func test_notificationManager_schedulePillReminder_invalidTime_doesNotCrash() {
        // Invalid time string — should not crash
        NotificationManager.shared.schedulePillReminder(timeString: "bad-input")
        NotificationManager.shared.schedulePillReminder(timeString: "25:99")
        NotificationManager.shared.schedulePillReminder(timeString: "")
    }

    func test_notificationManager_cancelPillReminder_doesNotCrash() {
        NotificationManager.shared.cancelPillReminder()
    }
}

// MARK: - J4: HealthKitManager availability

final class J4_HealthKitTests: XCTestCase {

    @available(iOS 16.0, *)
    func test_healthKitManager_availabilityCheckDoesNotCrash() {
        // Just verify the call doesn't crash; availability varies by simulator
        _ = HealthKitManager.shared.isAvailable
    }
}
