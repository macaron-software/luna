import SwiftUI

// MARK: - OnboardingView (5 étapes)

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Int = 0
    @State private var firstName: String = ""
    @State private var lastPeriodDate: Date? = nil
    @State private var periodDuration: Int = 5
    @State private var cycleRegularity: String = "regular"
    @State private var goals: Set<String> = ["track"]
    @State private var iCloudEnabled: Bool = false
    @State private var lockEnabled: Bool = true
    @State private var pin: String = ""
    @State private var pinConfirm: String = ""
    @State private var pinError: String? = nil
    @State private var isSettingUp: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color("LockBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                // Barre de progression
                ProgressBar(current: step, total: 5)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .accessibilityLabel(Text("onboarding_step_a11y \(step+1) sur 5"))

                // Contenu de l'étape
                TabView(selection: $step) {
                    WelcomeStep(firstName: $firstName).tag(0)
                    LastPeriodStep(selectedDate: $lastPeriodDate).tag(1)
                    CycleProfileStep(duration: $periodDuration, regularity: $cycleRegularity).tag(2)
                    GoalsStep(goals: $goals).tag(3)
                    PrivacySetupStep(
                        iCloud: $iCloudEnabled,
                        lock: $lockEnabled,
                        pin: $pin,
                        pinConfirm: $pinConfirm,
                        pinError: $pinError
                    ).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: step)

                // Navigation
                OnboardingNavBar(
                    step: step,
                    canProceed: canProceed,
                    isSettingUp: isSettingUp,
                    onNext: nextStep,
                    onBack: { step -= 1 }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var canProceed: Bool {
        switch step {
        case 4: return pin.count == 6 && pin == pinConfirm
        default: return true
        }
    }

    private func nextStep() {
        if step < 4 {
            step += 1
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        guard !isSettingUp else { return }
        isSettingUp = true

        Task {
            do {
                // Créer le vault avec le PIN choisi
                let engine = try LunaEngine.openVault(dbPath: appState.dbPath, pin: pin)

                // Stocker le PIN dans le Keychain si biométrie activée
                if lockEnabled {
                    KeychainService.shared.storePin(pin)
                }

                // Enregistrer les préférences de base
                await MainActor.run {
                    appState.engine = engine
                    appState.isVaultOpen = true
                    appState.userName = firstName.isEmpty ? nil : firstName
                    appState.isOnboardingDone = true
                }
            } catch {
                // Afficher erreur — unlikely ici car vault neuf
            }
            isSettingUp = false
        }
    }
}

// MARK: - Étape 1 — Bienvenue

struct WelcomeStep: View {
    @Binding var firstName: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "moon.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color("AccentPrimary"))
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("onboarding_welcome_title")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("onboarding_welcome_subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("onboarding_name_placeholder", text: $firstName)
                .textContentType(.givenName)
                .padding(16)
                .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(Text("onboarding_name_a11y"))
                .accessibilityHint(Text("onboarding_name_hint_a11y"))

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Étape 2 — Dernier cycle

struct LastPeriodStep: View {
    @Binding var selectedDate: Date?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            OnboardingStepHeader(
                icon: "drop.fill",
                title: "onboarding_last_period_title",
                subtitle: "onboarding_last_period_subtitle"
            )

            DatePicker(
                "onboarding_last_period_picker_label",
                selection: Binding(
                    get: { selectedDate ?? Date() },
                    set: { selectedDate = $0 }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .accessibilityLabel(Text("onboarding_date_picker_a11y"))

            Button("onboarding_skip") {
                selectedDate = nil
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(minHeight: 44)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Étape 3 — Profil cycle

struct CycleProfileStep: View {
    @Binding var duration: Int
    @Binding var regularity: String

    private let durations = [3, 4, 5, 6, 7]
    private let regularities = ["very_regular", "regular", "irregular", "unknown"]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            OnboardingStepHeader(
                icon: "arrow.triangle.2.circlepath",
                title: "onboarding_cycle_profile_title",
                subtitle: "onboarding_cycle_profile_subtitle"
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("onboarding_period_duration_label")
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    ForEach(durations, id: \.self) { d in
                        Button("\(d)j") {
                            duration = d
                        }
                        .buttonStyle(SelectableButtonStyle(isSelected: duration == d))
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    Button("7j+") { duration = 8 }
                        .buttonStyle(SelectableButtonStyle(isSelected: duration >= 8))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("onboarding_regularity_label")
                    .font(.subheadline.bold())
                VStack(spacing: 8) {
                    ForEach(regularities, id: \.self) { reg in
                        Button {
                            regularity = reg
                        } label: {
                            HStack {
                                Text(LocalizedStringKey("regularity_\(reg)"))
                                Spacer()
                                if regularity == reg {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AccentPrimary"))
                                }
                            }
                            .padding(14)
                            .background(
                                regularity == reg ? Color("AccentPrimary").opacity(0.1) : Color("CardBackground"),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .foregroundStyle(.primary)
                        .frame(minHeight: 44)
                        .accessibilityAddTraits(regularity == reg ? .isSelected : [])
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Étape 4 — Objectifs

struct GoalsStep: View {
    @Binding var goals: Set<String>

    private let allGoals = [
        "track", "understand_symptoms", "avoid_pregnancy",
        "try_to_conceive", "track_pregnancy", "perimenopause"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            OnboardingStepHeader(
                icon: "star.fill",
                title: "onboarding_goals_title",
                subtitle: "onboarding_goals_subtitle"
            )

            VStack(spacing: 8) {
                ForEach(allGoals, id: \.self) { goal in
                    Button {
                        if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
                    } label: {
                        HStack {
                            Image(systemName: goals.contains(goal) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(goals.contains(goal) ? Color("AccentPrimary") : .secondary)
                                .accessibilityHidden(true)
                            Text(LocalizedStringKey("goal_\(goal)"))
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            goals.contains(goal) ? Color("AccentPrimary").opacity(0.1) : Color("CardBackground"),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .foregroundStyle(.primary)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(goals.contains(goal) ? .isSelected : [])
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Étape 5 — Vie privée

struct PrivacySetupStep: View {
    @Binding var iCloud: Bool
    @Binding var lock: Bool
    @Binding var pin: String
    @Binding var pinConfirm: String
    @Binding var pinError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                OnboardingStepHeader(
                    icon: "lock.shield.fill",
                    title: "onboarding_privacy_title",
                    subtitle: "onboarding_privacy_subtitle"
                )

                // Illustration privacy
                HStack(spacing: 8) {
                    Image(systemName: "iphone")
                    Image(systemName: "lock.fill")
                }
                .font(.system(size: 48))
                .foregroundStyle(Color("AccentPrimary"))
                .accessibilityHidden(true)

                Text("onboarding_privacy_guarantee")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Toggle(isOn: $iCloud) {
                    Label("onboarding_icloud_toggle", systemImage: "icloud.fill")
                }
                .padding(14)
                .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
                .disabled(true) // Tier 2

                Toggle(isOn: $lock) {
                    Label("onboarding_lock_toggle", systemImage: "lock.fill")
                }
                .padding(14)
                .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))

                if lock {
                    PINSetupView(pin: $pin, pinConfirm: $pinConfirm, error: $pinError)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - PINSetupView

struct PINSetupView: View {
    @Binding var pin: String
    @Binding var pinConfirm: String
    @Binding var error: String?
    @State private var confirmActive: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text(confirmActive ? "onboarding_pin_confirm_label" : "onboarding_pin_create_label")
                .font(.subheadline.bold())

            SecureField(confirmActive ? "onboarding_pin_confirm_placeholder" : "onboarding_pin_placeholder",
                        text: confirmActive ? $pinConfirm : $pin)
                .keyboardType(.numberPad)
                .textContentType(.newPassword)
                .padding(12)
                .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: pin) { _, v in if v.count == 6 && !confirmActive { confirmActive = true } }
                .onChange(of: pinConfirm) { _, v in
                    if v.count == 6 {
                        error = v != pin ? NSLocalizedString("onboarding_pin_mismatch", comment: "") : nil
                    }
                }

            if let err = error {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Composants partagés

struct OnboardingStepHeader: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color("AccentPrimary"))
                .accessibilityHidden(true)
            Text(title).font(.title2.bold()).multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }
}

struct SelectableButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color("AccentPrimary") : Color("CardBackground"),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.2)).frame(height: 4)
                Capsule()
                    .fill(Color("AccentPrimary"))
                    .frame(width: geo.size.width * CGFloat(current + 1) / CGFloat(total), height: 4)
                    .animation(.easeInOut, value: current)
            }
        }
        .frame(height: 4)
    }
}

struct OnboardingNavBar: View {
    let step: Int
    let canProceed: Bool
    let isSettingUp: Bool
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        HStack {
            if step > 0 {
                Button("onboarding_back") { onBack() }
                    .frame(minHeight: 44)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onNext()
            } label: {
                if isSettingUp {
                    ProgressView().tint(.white)
                } else {
                    Text(step == 4 ? "onboarding_start_button" : "onboarding_next_button")
                        .bold()
                }
            }
            .disabled(!canProceed || isSettingUp)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(canProceed ? Color("AccentPrimary") : Color.secondary.opacity(0.3), in: Capsule())
            .foregroundStyle(.white)
            .accessibilityLabel(step == 4
                ? Text("onboarding_start_a11y")
                : Text("onboarding_next_a11y")
            )
        }
    }
}
