import SwiftUI

// MARK: - TrackingMode extension (generated enum helper)

extension TrackingMode {
    var rawString: String {
        switch self {
        case .regular:      return "regular"
        case .ttc:          return "ttc"
        case .pregnant:     return "pregnant"
        case .postpartum:   return "postpartum"
        case .perimenopause:return "perimenopause"
        }
    }

    static func from(_ str: String) -> TrackingMode {
        switch str {
        case "ttc":          return .ttc
        case "pregnant":     return .pregnant
        case "postpartum":   return .postpartum
        case "perimenopause":return .perimenopause
        default:             return .regular
        }
    }
}

// MARK: - TrackingModeView

/// Sélecteur du mode de suivi + configuration TTC / grossesse.
struct TrackingModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: TrackingMode = .regular
    @State private var edd: Date = Date()
    @State private var showEDDPicker = false
    @Environment(\.dismiss) private var dismiss

    private let modes: [(TrackingMode, String, String)] = [
        (.regular,      "tracking_mode_regular",       "arrow.triangle.2.circlepath"),
        (.ttc,          "tracking_mode_ttc",            "heart.fill"),
        (.pregnant,     "tracking_mode_pregnant",       "figure.maternity"),
        (.postpartum,   "tracking_mode_postpartum",     "figure.and.child.holdinghands"),
        (.perimenopause,"tracking_mode_perimenopause",  "waveform.path.ecg"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(modes, id: \.0.rawString) { (mode, labelKey, icon) in
                        Button {
                            selectedMode = mode
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .foregroundStyle(Color("AccentPrimary"))
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(LocalizedStringKey(labelKey))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AccentPrimary"))
                                        .accessibilityLabel(Text("selected_a11y"))
                                }
                            }
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Text("tracking_mode_section_header")
                }

                if selectedMode == .pregnant {
                    Section {
                        Toggle("tracking_edd_label", isOn: $showEDDPicker)
                        if showEDDPicker {
                            DatePicker(
                                "tracking_edd_date",
                                selection: $edd,
                                in: Date()...,
                                displayedComponents: .date
                            )
                        }
                    } header: {
                        Text("tracking_edd_section")
                    }
                }
            }
            .navigationTitle("settings_tracking_mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save_button") {
                        saveProfile()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button") { dismiss() }
                }
            }
            .onAppear(perform: loadProfile)
        }
    }

    private func loadProfile() {
        guard let engine = appState.engine else { return }
        Task {
            if let profile = try? engine.getUserProfile() {
                await MainActor.run {
                    selectedMode = profile.trackingMode
                    if let eddStr = profile.edd,
                       let d = ISO8601DateFormatter().date(from: eddStr) {
                        edd = d
                        showEDDPicker = true
                    }
                }
            }
        }
    }

    private func saveProfile() {
        guard let engine = appState.engine else { return }
        Task {
            guard var profile = try? engine.getUserProfile() else { return }
            profile.trackingMode = selectedMode
            if selectedMode == .pregnant && showEDDPicker {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                profile.edd = fmt.string(from: edd)
            } else {
                profile.edd = nil
            }
            try? engine.setUserProfile(profile: profile)
        }
    }
}
