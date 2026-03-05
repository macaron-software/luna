import SwiftUI

@main
struct LunaApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

// MARK: - AppState

/// État global de l'application — partagé via @EnvironmentObject.
/// Toutes les propriétés publiées déclenchent des re-renders SwiftUI.
final class AppState: ObservableObject {

    // ── Vault ──────────────────────────────────────────────────────────────
    /// Engine Rust (nil = vault verrouillé ou pas encore ouvert)
    @Published var engine: LunaEngine? = nil

    /// Alias pratique pour les vues qui vérifient si le vault est accessible
    var isVaultOpen: Bool {
        get { engine != nil }
        set { if !newValue { engine = nil } }
    }

    /// Vault verrouillé (inverse de isVaultOpen, conservé pour rétrocompatibilité)
    var isLocked: Bool { engine == nil }

    // ── Onboarding ─────────────────────────────────────────────────────────
    @Published var isOnboardingDone: Bool {
        didSet { defaults.set(isOnboardingDone, forKey: "onboarding_done") }
    }
    /// Alias pour RootView
    var isOnboardingComplete: Bool { isOnboardingDone }

    // ── Profil utilisateur ─────────────────────────────────────────────────
    @Published var userName: String? {
        didSet { defaults.set(userName, forKey: "user_name") }
    }
    @Published var lockEnabled: Bool {
        didSet { defaults.set(lockEnabled, forKey: "lock_enabled") }
    }
    @Published var colorScheme: ColorScheme? = nil

    // ── Mode Calme (psy a11y) ─────────────────────────────────────────────
    /// Calm mode: hides cycle predictions to reduce anxiety.
    /// Designed for users with anxiety, PTSD, or who find predictions triggering.
    @Published var calmMode: Bool {
        didSet { defaults.set(calmMode, forKey: "calm_mode") }
    }

    // ── Données cycle (pour CalendarView) ──────────────────────────────────
    @Published var cycleEvents: [String: CycleEventType] = [:]

    // ── Stats (pour InsightsView) ──────────────────────────────────────────
    @Published var averageCycleLength: Double? = nil
    @Published var averagePeriodLength: Double? = nil

    // ── Storage ────────────────────────────────────────────────────────────
    private let defaults = UserDefaults.standard

    /// Chemin absolu vers la base SQLite (dans le sandbox Documents de l'app).
    var dbPath: String { AppState.sharedDbPath }

    static var sharedDbPath: String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("luna.db").path
    }

    init() {
        isOnboardingDone = defaults.bool(forKey: "onboarding_done")
        userName = defaults.string(forKey: "user_name")
        lockEnabled = defaults.bool(forKey: "lock_enabled")
        calmMode = defaults.bool(forKey: "calm_mode")

        #if DEBUG
        // UI testing bypass: -UITesting argument auto-opens vault with PIN "123456"
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            isOnboardingDone = true
            lockEnabled = false
            if userName == nil { userName = "Luna" }
            let dbPath = AppState.sharedDbPath
            let debugFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("luna_debug.txt")
            do {
                engine = try LunaEngine.openVault(dbPath: dbPath, pin: "123456")
                try? "OK: vault opened at \(dbPath)".write(to: debugFile, atomically: true, encoding: .utf8)
            } catch {
                try? "FAIL: \(error) at \(dbPath)".write(to: debugFile, atomically: true, encoding: .utf8)
            }
        }
        #endif
    }

    // ── Actions ────────────────────────────────────────────────────────────

    func openVault(pin: String) throws {
        engine = try LunaEngine.openVault(dbPath: dbPath, pin: pin)
        Task { await refreshCycleData() }
    }

    func lock() {
        engine = nil
    }

    /// Recharge les événements cycle + stats depuis le Rust core.
    @MainActor
    func refreshCycleData() async {
        guard let engine else { return }
        // TODO: appeler engine.listCycles() et construire cycleEvents + stats
        // Implémentation complète en Phase 1 sprint 2
        _ = engine
    }
}
