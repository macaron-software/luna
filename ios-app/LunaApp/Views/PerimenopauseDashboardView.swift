import SwiftUI

// MARK: - Perimenopause Dashboard View

/// Dedicated view for perimenopause tracking mode.
/// Prominently surfaces hot flash, night sweats, vaginal dryness logging
/// and shows cycle variability chart.
struct PerimenopauseDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var cycleVariance: [Double] = []
    @State private var showLogSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Header ──────────────────────────────────────────────
                Text(NSLocalizedString("perimeno.dashboard_title", comment: ""))
                    .font(.title2).bold()
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                // ── Key symptoms quick-log ───────────────────────────────
                PerimenopauseSymptomPanel(showLogSheet: $showLogSheet)
                    .padding(.horizontal)

                // ── Cycle variability chart ──────────────────────────────
                PerimenopauseCycleVarianceSection()
                    .padding(.horizontal)

                // ── Info card (science-based) ────────────────────────────
                PerimenopauseInfoCard()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showLogSheet) {
            LogSheetView(date: Date())
                .environmentObject(appState)
        }
    }
}

// MARK: - Symptom Quick-Log Panel

private struct PerimenopauseSymptomPanel: View {
    @Binding var showLogSheet: Bool

    private let keySymptoms: [(key: String, localKey: String)] = [
        ("hot_flash",       "symptom.hot_flash"),
        ("night_sweats",    "symptom.night_sweats"),
        ("vaginal_dryness", "symptom.vaginal_dryness"),
        ("insomnia",        "symptom.insomnia"),
        ("low_mood",        "symptom.low_mood"),
        ("anxiety",         "symptom.anxiety"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("perimeno.key_symptoms", comment: ""))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(keySymptoms, id: \.key) { item in
                    Button(action: { showLogSheet = true }) {
                        HStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 8, height: 8)
                            Text(NSLocalizedString(item.localKey, comment: ""))
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        String(format: NSLocalizedString("a11y.log_symptom", comment: ""),
                               NSLocalizedString(item.localKey, comment: ""))
                    )
                }
            }

            Button(action: { showLogSheet = true }) {
                Label(
                    NSLocalizedString("perimeno.log_today_button", comment: ""),
                    systemImage: "plus.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("log_button_a11y")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Cycle Variability Section

private struct PerimenopauseCycleVarianceSection: View {
    @EnvironmentObject var appState: AppState
    @State private var cycleLengths: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("perimeno.cycle_variability", comment: ""))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if cycleLengths.isEmpty {
                Text(NSLocalizedString("insights.no_data", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Variance bar chart using same TrendChartsSection pattern
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(cycleLengths.enumerated()), id: \.offset) { _, length in
                            let maxLen = cycleLengths.max() ?? 40
                            let height = geo.size.height * CGFloat(length / max(maxLen, 1))
                            Rectangle()
                                .fill(varianceColor(length: length))
                                .frame(width: max(6, geo.size.width / CGFloat(cycleLengths.count) - 4),
                                       height: height)
                                .cornerRadius(3)
                        }
                    }
                }
                .frame(height: 80)

                // Variance statistic
                if cycleLengths.count >= 2 {
                    let variance = computeVariance(cycleLengths)
                    HStack {
                        Text(NSLocalizedString("perimeno.variance_label", comment: ""))
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f " + NSLocalizedString("unit.days", comment: ""), variance))
                            .font(.caption).bold()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .task { await loadCycles() }
    }

    @MainActor
    private func loadCycles() async {
        guard let engine = appState.engine else { return }
        if let cycles = try? engine.getCycles(limit: 12) {
            // Compute lengths from consecutive start dates
            let starts = cycles.compactMap { $0.start() }.sorted()
            cycleLengths = zip(starts, starts.dropFirst()).map {
                Double(Calendar.current.dateComponents([.day], from: $0, to: $1).day ?? 28)
            }
        }
    }

    private func varianceColor(length: Double) -> Color {
        switch length {
        case ..<21: return .red.opacity(0.7)
        case 21..<25: return .orange.opacity(0.7)
        case 25..<35: return .accentColor
        default: return .orange.opacity(0.7)
        }
    }

    private func computeVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let sumSq = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
        return (sumSq / Double(values.count)).squareRoot()
    }
}

// MARK: - Info Card (science-based)

private struct PerimenopauseInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("perimeno.info_title", comment: ""))
                .font(.subheadline).bold()

            Text(NSLocalizedString("perimeno.info_body", comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Perimenopause Banner (for HomeView)

struct PerimenopauseBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Text("P")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.purple)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("perimeno.banner_title", comment: ""))
                    .font(.subheadline).bold()
                Text(NSLocalizedString("perimeno.banner_subtitle", comment: ""))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink(destination: PerimenopauseDashboardView()) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.06))
        .cornerRadius(12)
        .accessibilityLabel(NSLocalizedString("perimeno.banner_a11y", comment: ""))
    }
}

// MARK: - Extension Cycle.start()

private extension Cycle {
    func start() -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: startDate)
    }
}
