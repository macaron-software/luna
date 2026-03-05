import SwiftUI

// MARK: - PregnancyLogSheet

/// Fiche de saisie quotidienne pour le mode grossesse.
struct PregnancyLogSheet: View {
    @EnvironmentObject var appState: AppState
    let date: Date
    @State private var hcgPositive: Bool? = nil
    @State private var kicks: Double = 0
    @State private var nauseaLevel: Int = 0
    @State private var weightKg: String = ""
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Test hCG
                Section("pregnancy_hcg_section") {
                    Picker("pregnancy_hcg_result", selection: $hcgPositive) {
                        Text("pregnancy_hcg_not_done").tag(Optional<Bool>.none)
                        Text("pregnancy_hcg_positive").tag(Optional<Bool>.some(true))
                        Text("pregnancy_hcg_negative").tag(Optional<Bool>.some(false))
                    }
                    .pickerStyle(.segmented)
                    .frame(minHeight: 44)
                }

                // Mouvements foetaux
                Section("pregnancy_kicks_section") {
                    HStack {
                        Text("pregnancy_kicks_label")
                        Spacer()
                        Stepper("\(Int(kicks))", value: $kicks, in: 0...200)
                            .labelsHidden()
                        Text("\(Int(kicks))")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                    .frame(minHeight: 44)
                }

                // Nausées
                Section("pregnancy_nausea_section") {
                    PregnancyMoodScale(value: $nauseaLevel, labelKey: "pregnancy_nausea_level")
                }

                // Poids
                Section("pregnancy_weight_section") {
                    HStack {
                        TextField("log_weight_placeholder", text: $weightKg)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                }

                // Notes
                Section("log_notes_label") {
                    TextField("log_notes_placeholder", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("pregnancy_log_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save_button") {
                        saveLog()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel_button") { dismiss() }
                }
            }
            .onAppear(perform: loadLog)
        }
    }

    private func loadLog() {
        guard let engine = appState.engine else { return }
        Task {
            if let log = try? engine.getPregnancyLog(date: dateString) {
                await MainActor.run {
                    hcgPositive = log.hcgPositive
                    kicks = Double(log.kicks ?? 0)
                    nauseaLevel = Int(log.nauseaLevel ?? 0)
                    weightKg = log.weightKg.map { String(format: "%.1f", $0) } ?? ""
                    notes = log.notes ?? ""
                }
            }
        }
    }

    private func saveLog() {
        guard let engine = appState.engine else { return }
        let kicksVal: UInt8? = kicks > 0 ? UInt8(min(Int(kicks), 255)) : nil
        let nauseaVal: UInt8? = nauseaLevel > 0 ? UInt8(nauseaLevel) : nil
        let log = PregnancyLog(
            id: UUID().uuidString,
            date: dateString,
            hcgPositive: hcgPositive,
            kicks: kicksVal,
            nauseaLevel: nauseaVal,
            weightKg: Double(weightKg.replacingOccurrences(of: ",", with: ".")),
            symptoms: [],
            notes: notes.isEmpty ? nil : notes
        )
        Task { try? engine.logPregnancyDay(log: log) }
    }
}

// MARK: - Scale 1-5 réutilisable

private struct PregnancyMoodScale: View {
    @Binding var value: Int
    let labelKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(labelKey))
                .font(.subheadline)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { v in
                    Button {
                        value = (value == v) ? 0 : v
                    } label: {
                        ZStack {
                            Circle()
                                .fill(value == v ? Color("AccentPrimary") : Color("CardBackground"))
                            Circle()
                                .strokeBorder(value == v ? Color("AccentPrimary") : Color.secondary.opacity(0.35), lineWidth: 1.5)
                            Text("\(v)")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(value == v ? .white : .secondary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text("\(v)"))
                }
            }
        }
    }
}
