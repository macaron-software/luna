import SwiftUI

struct LogSheetView: View {
    let date: Date
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedSymptoms: Set<String> = []
    @State private var mood: Int = 0       // 0 = non défini, 1-5
    @State private var energy: Int = 0
    @State private var flow: String = "none"
    @State private var notes: String = ""
    @State private var showAdvanced: Bool = false
    @State private var bbt: String = ""
    @State private var isSaving: Bool = false

    // Symptômes rapides affichés en surface (les plus courants)
    private let quickSymptoms = [
        "cramps", "bloating", "fatigue", "headache",
        "breast_tenderness", "irritability", "low_mood",
        "high_energy", "motivation",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Date ──────────────────────────────────────────────
                    Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.title3.bold())
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)

                    // ── Humeur ────────────────────────────────────────────
                    MoodPicker(selection: $mood)
                        .padding(.horizontal)

                    // ── Énergie ───────────────────────────────────────────
                    EnergyPicker(selection: $energy)
                        .padding(.horizontal)

                    // ── Règles ────────────────────────────────────────────
                    FlowPicker(selection: $flow)
                        .padding(.horizontal)

                    // ── Symptômes rapides ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("symptoms_section_title")
                            .font(.subheadline.bold())
                            .padding(.horizontal)
                            .accessibilityAddTraits(.isHeader)

                        SymptomChipsRow(
                            symptoms: quickSymptoms,
                            selected: $selectedSymptoms
                        )
                        .padding(.horizontal)
                    }

                    // ── Section avancée (BBT, LH, glaire) ────────────────
                    DisclosureGroup(
                        isExpanded: $showAdvanced,
                        content: {
                            AdvancedBiometricsView(bbt: $bbt)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        },
                        label: {
                            Label("advanced_section_title", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color("AccentSecondary"))
                        }
                    )
                    .padding(.horizontal)
                    .animation(reduceMotion ? .none : .default, value: showAdvanced)

                    // ── Note libre ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("notes_label")
                            .font(.subheadline.bold())
                            .padding(.horizontal)
                        TextField("notes_placeholder", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .accessibilityLabel(Text("notes_a11y"))
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 20)
            }
            .navigationTitle("log_sheet_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save_button") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                    .bold()
                }
            }
        }
    }

    private func save() async {
        guard let engine = appState.engine else { return }
        isSaving = true
        defer { isSaving = false }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dateStr = fmt.string(from: date)

        var log = DailyLog(
            id: UUID().uuidString,
            date: dateStr,
            symptoms: Array(selectedSymptoms),
            mood: mood > 0 ? UInt8(mood) : nil,
            energy: energy > 0 ? UInt8(energy) : nil,
            bbt: Double(bbt),
            lhTest: nil,
            cervicalMucus: nil,
            sexualActivity: nil,
            flow: flow == "none" ? nil : flow,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try engine.logDay(log: log)
            // Annonce d'accessibilité après sauvegarde
            UIAccessibility.post(
                notification: .announcement,
                argument: NSLocalizedString("log_saved_a11y", comment: "")
            )
            dismiss()
        } catch {
            // TODO: afficher une alerte d'erreur
        }
    }
}

// MARK: - MoodPicker

struct MoodPicker: View {
    @Binding var selection: Int
    private let keys = ["mood_very_bad", "mood_bad", "mood_neutral", "mood_good", "mood_great"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("mood_label")
                .font(.subheadline.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        selection = (selection == value) ? 0 : value
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selection == value ? Color("AccentPrimary") : Color("CardBackground"))
                            Circle()
                                .strokeBorder(
                                    selection == value ? Color("AccentPrimary") : Color.secondary.opacity(0.35),
                                    lineWidth: 1.5
                                )
                            Text("\(value)")
                                .font(.callout.weight(.medium))
                                .foregroundColor(selection == value ? .white : .secondary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text(LocalizedStringKey(keys[value - 1])))
                    .accessibilityAddTraits(selection == value ? .isSelected : [])
                    .accessibilityHint(
                        Text(selection == value ? "tap_to_deselect_a11y" : "tap_to_select_a11y")
                    )
                }
            }

            if selection > 0 {
                Text(LocalizedStringKey(keys[selection - 1]))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - EnergyPicker

struct EnergyPicker: View {
    @Binding var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("energy_label")
                .font(.subheadline.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                Image(systemName: "battery.0")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Slider(value: Binding(
                    get: { Double(selection) },
                    set: { selection = Int($0.rounded()) }
                ), in: 0...5, step: 1)
                .accessibilityLabel(Text("energy_slider_a11y"))
                .accessibilityValue(Text("energy_value_\(selection)_a11y"))

                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color("AccentPrimary"))
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - FlowPicker

struct FlowPicker: View {
    @Binding var selection: String
    private let options = ["none", "spotting", "light", "medium", "heavy"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("flow_label")
                .font(.subheadline.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        selection = opt
                    } label: {
                        Text(LocalizedStringKey("flow_\(opt)"))
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selection == opt
                                    ? Color("AccentPrimary")
                                    : Color("CardBackground"),
                                in: Capsule()
                            )
                            .foregroundStyle(selection == opt ? .white : .primary)
                    }
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(selection == opt ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - SymptomChipsRow

struct SymptomChipsRow: View {
    let symptoms: [String]
    @Binding var selected: Set<String>

    var body: some View {
        // Grille de chips — wrapping layout
        FlowLayout(spacing: 8) {
            ForEach(symptoms, id: \.self) { symptom in
                SymptomChip(
                    symptom: symptom,
                    isSelected: selected.contains(symptom)
                ) {
                    if selected.contains(symptom) {
                        selected.remove(symptom)
                    } else {
                        selected.insert(symptom)
                    }
                }
            }
        }
    }
}

struct SymptomChip: View {
    let symptom: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(LocalizedStringKey("symptom_\(symptom)"))
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color("AccentPrimary") : Color("CardBackground"),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.clear : Color.secondary.opacity(0.3),
                        lineWidth: 1
                    )
                )
        }
        .frame(minHeight: 44) // a11y: cible ≥ 44pt
        .accessibilityLabel(Text(LocalizedStringKey("symptom_\(symptom)_a11y")))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(
            Text(isSelected ? "tap_to_deselect_a11y" : "tap_to_select_symptom_a11y")
        )
    }
}

// MARK: - AdvancedBiometricsView

struct AdvancedBiometricsView: View {
    @Binding var bbt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // BBT
            HStack {
                VStack(alignment: .leading) {
                    Text("bbt_label")
                        .font(.subheadline.bold())
                    Text("bbt_hint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TextField("bbt_placeholder", text: $bbt)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .accessibilityLabel(Text("bbt_a11y_label"))
                    .accessibilityHint(Text("bbt_a11y_hint"))
            }
        }
    }
}

// MARK: - FlowLayout (chip wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += maxH + spacing
                maxH = 0
            }
            x += size.width + spacing
            maxH = max(maxH, size.height)
        }
        return CGSize(width: width, height: y + maxH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += maxH + spacing
                maxH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxH = max(maxH, size.height)
        }
    }
}
