import Foundation
import HealthKit

/// Intégration HealthKit — optionnelle, nécessite consentement explicite.
/// Seules les données menstruelles et la température basale sont écrites/lues.
/// Aucune donnée n'est transmise à Apple ou des tiers — HealthKit reste local.
@available(iOS 16.0, *)
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // Types que LUNA écrit
    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let menstrual = HKObjectType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstrual)
        }
        return types
    }

    // Types que LUNA lit
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let bbt = HKObjectType.quantityType(forIdentifier: .basalBodyTemperature) {
            types.insert(bbt)
        }
        if let menstrual = HKObjectType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstrual)
        }
        return types
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    /// Écrit un log de flux menstruel dans HealthKit
    func writeMenstrualFlow(date: Date, flow: String) async {
        guard isAvailable,
              let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return }

        let value: Int
        switch flow {
        case "spotting": value = HKCategoryValueMenstrualFlow.light.rawValue
        case "light":    value = HKCategoryValueMenstrualFlow.light.rawValue
        case "medium":   value = HKCategoryValueMenstrualFlow.medium.rawValue
        case "heavy":    value = HKCategoryValueMenstrualFlow.heavy.rawValue
        default:         value = HKCategoryValueMenstrualFlow.none.rawValue
        }

        let sample = HKCategorySample(
            type: type,
            value: value,
            start: date,
            end: date.addingTimeInterval(86400)
        )
        try? await store.save(sample)
    }

    /// Lit la dernière température basale depuis HealthKit
    func readLatestBBT() async -> Double? {
        guard isAvailable,
              let type = HKObjectType.quantityType(forIdentifier: .basalBodyTemperature) else { return nil }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                      sortDescriptors: [sort]) { _, results, _ in
                guard let sample = results?.first as? HKQuantitySample else {
                    cont.resume(returning: nil)
                    return
                }
                cont.resume(returning: sample.quantity.doubleValue(for: .degreeCelsius()))
            }
            store.execute(query)
        }
    }
}
