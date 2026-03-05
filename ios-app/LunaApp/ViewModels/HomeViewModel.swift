import Foundation

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var prediction: Prediction? = nil
    @Published var currentCycleDay: Int = 1
    @Published var currentPhase: String? = nil
    @Published var dailyInsight: String? = nil
    @Published var trackingMode: String = "regular"

    func load(engine: LunaEngine?) async {
        guard let engine else { return }
        do {
            prediction = try engine.predictNext()
            // TODO: calculer currentCycleDay et phase depuis les cycles
        } catch {
            // Silencieux — l'UI affiche "pas encore de données"
        }
        if let profile = try? engine.getUserProfile() {
            self.trackingMode = profile.trackingMode.rawString
        }
    }
}
