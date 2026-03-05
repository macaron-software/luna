import XCTest
@testable import LunaApp

/// Tests unitaires supplémentaires — NotificationManager et HealthKitManager
final class LunaServicesTests: XCTestCase {

    func testNotificationManagerSingleton() {
        let nm1 = NotificationManager.shared
        let nm2 = NotificationManager.shared
        XCTAssertTrue(nm1 === nm2)
    }

    func testHealthKitManagerAvailabilityCheck() {
        // Sur simulateur, HealthKit n'est pas disponible
        // On vérifie juste que l'appel ne crash pas
        if #available(iOS 16.0, *) {
            let _ = HealthKitManager.shared.isAvailable
        }
    }

    func testTrackingMode_rawString_regular() {
        XCTAssertEqual(TrackingMode.regular.rawString, "regular")
    }

    func testTrackingMode_rawString_ttc() {
        XCTAssertEqual(TrackingMode.ttc.rawString, "ttc")
    }

    func testTrackingMode_from_pregnant() {
        XCTAssertEqual(TrackingMode.from("pregnant"), .pregnant)
    }

    func testTrackingMode_from_unknown_defaultsToRegular() {
        XCTAssertEqual(TrackingMode.from("unknown"), .regular)
    }
}
