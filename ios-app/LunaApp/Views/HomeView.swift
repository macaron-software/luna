import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeViewModel()
    @State private var showLogSheet = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    if appState.calmMode {
                        // ── Mode calme — bannière empathique ─────────────
                        CalmModeBanner()
                            .padding(.horizontal)
                    } else {
                        // ── Cycle progress donut ──────────────────────────
                        CycleProgressWidget(prediction: vm.prediction, currentDay: vm.currentCycleDay)
                            .padding(.horizontal)
                            .animation(reduceMotion ? .none : .spring(response: 0.5), value: vm.currentCycleDay)

                        // ── Mini calendrier 7 jours ───────────────────────
                        WeekStripView(prediction: vm.prediction)
                            .padding(.horizontal)
                    }

                    // ── Symptômes attendus (science-based) ────────────
                    if let phase = vm.currentPhase {
                        ExpectedSymptomsCard(phase: phase)
                            .padding(.horizontal)
                    }

                    // ── Insight du jour ───────────────────────────────
                    if let insight = vm.dailyInsight {
                        InsightCard(text: insight)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 16)
            }
            .navigationTitle("nav_today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PrivacyBadge()
                }
            }
            .overlay(alignment: .bottom) {
                LogButton { showLogSheet = true }
                    .padding(.bottom, 16)
            }
            .sheet(isPresented: $showLogSheet) {
                LogSheetView(date: Date())
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await vm.load(engine: appState.engine)
            }
        }
    }
}

// MARK: - CalmModeBanner

private struct CalmModeBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(Color("AccentSuccess"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("home_calm_no_prediction")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(Text("home_calm_no_prediction"))
    }
}

// MARK: - CycleProgressWidget

struct CycleProgressWidget: View {
    let prediction: Prediction?
    let currentDay: Int

    var body: some View {
        VStack(spacing: 12) {
            // Donut progress
            ZStack {
                Circle()
                    .stroke(Color("PhaseColor").opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color("PhaseColor"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                VStack(spacing: 4) {
                    Text("cycle_day_label \(currentDay)")
                        .font(.title2.bold())
                    if let phase = phaseLabel {
                        Text(phase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 160, height: 160)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)

            if let prediction {
                Text("next_period_in \(daysUntilNext(prediction))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 20))
    }

    private var progress: Double {
        guard let p = prediction, let next = nextPeriodDate(p) else { return 0 }
        let cycleLen = Double(currentDay) + Double(daysUntilNext(p))
        return cycleLen > 0 ? Double(currentDay) / cycleLen : 0
    }

    private var phaseLabel: String? { nil } // TODO: via PredictionEngine.phaseForDate

    private var accessibilityDescription: String {
        guard let p = prediction else {
            return NSLocalizedString("cycle_no_data_a11y", comment: "Pas de données de cycle")
        }
        return String(
            format: NSLocalizedString("cycle_progress_a11y", comment: ""),
            currentDay, daysUntilNext(p)
        )
    }

    private func daysUntilNext(_ p: Prediction) -> Int {
        guard let next = nextPeriodDate(p) else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
    }

    private func nextPeriodDate(_ p: Prediction) -> Date? {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.date(from: p.nextPeriodStart)
    }
}

// MARK: - LogButton

struct LogButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("log_today_button", systemImage: "plus.circle.fill")
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color("AccentPrimary"), in: Capsule())
                .foregroundStyle(.white)
        }
        .accessibilityLabel(Text("log_today_a11y"))
        .accessibilityHint(Text("log_today_hint_a11y"))
        // Cible tactile ≥ 44pt garantie par le padding
    }
}

// MARK: - PrivacyBadge

struct PrivacyBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .imageScale(.small)
            Text("privacy_local_badge")
                .font(.caption2)
        }
        .foregroundStyle(Color("AccentPrimary"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("AccentPrimary").opacity(0.12), in: Capsule())
        .accessibilityLabel(Text("privacy_badge_a11y"))
    }
}

// MARK: - Placeholder views

struct ExpectedSymptomsCard: View {
    let phase: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("expected_symptoms_title")
                .font(.subheadline.bold())
            Text("symptoms_for_phase_\(phase)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WeekStripView: View {
    let prediction: Prediction?
    var body: some View {
        Text("week_strip_placeholder")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

struct InsightCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color("AccentSecondary"))
            Text(text)
                .font(.subheadline)
        }
        .padding(16)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("insight_a11y_prefix") + Text(text))
    }
}
