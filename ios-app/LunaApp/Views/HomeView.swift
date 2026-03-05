import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeViewModel()
    @State private var showLogSheet = false
    @State private var showPregnancyLog = false
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

                    // ── Bannière mode grossesse ─────────────────────────────
                    if vm.trackingMode == "pregnant" {
                        PregnancyBanner { showPregnancyLog = true }
                            .padding(.horizontal)
                    }
                    // ── Bannière mode TTC ──────────────────────────────────
                    if vm.trackingMode == "ttc" {
                        TTCBanner()
                            .padding(.horizontal)
                    }
                    // ── Bannière mode péri-ménopause ───────────────────────
                    if vm.trackingMode == "perimenopause" {
                        PerimenopauseBanner()
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
            .sheet(isPresented: $showPregnancyLog) {
                PregnancyLogSheet(date: Date())
                    .presentationDetents([.large])
                    .environmentObject(appState)
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

// MARK: - Tracking Mode Banners

private struct PregnancyBanner: View {
    let onLog: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.maternity")
                .foregroundStyle(Color("AccentPrimary"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("home_pregnant_title").font(.subheadline.bold())
                Text("home_pregnant_subtitle").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("home_log_button", action: onLog)
                .font(.caption.bold())
                .foregroundStyle(Color("AccentPrimary"))
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(14)
        .background(Color("AccentPrimary").opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct TTCBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .foregroundStyle(Color("AccentAccent"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("home_ttc_title").font(.subheadline.bold())
                Text("home_ttc_subtitle").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color("AccentAccent").opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SegmentedCycleRing

/// Anneau segmenté : un arc par jour du cycle, coloré par phase.
struct SegmentedCycleRing: View {
    let totalDays: Int        // durée totale du cycle (ex. 28)
    let currentDay: Int       // jour actuel dans le cycle
    let menstrualEnd: Int     // dernier jour des règles (ex. 5)
    let fertileStart: Int     // premier jour fenêtre fertile
    let fertileEnd: Int       // dernier jour fenêtre fertile
    let ovulationCycleDay: Int? // numéro de jour de l'ovulation

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let lineWidth: CGFloat = 13
    private let gapDeg: Double = 2.5  // espace entre segments en degrés

    // Couleurs par phase (correspond à la palette LUNA)
    private let colorMenstrual   = Color(red: 0.761, green: 0.337, blue: 0.478) // #C2567A rose
    private let colorFollicular  = Color(red: 0.910, green: 0.647, blue: 0.596) // #E8A598 pêche
    private let colorFertile     = Color(red: 0.478, green: 0.722, blue: 0.569) // #7AB891 sauge
    private let colorLuteal      = Color(red: 0.420, green: 0.306, blue: 0.443) // #6B4E71 prune

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let center = CGPoint(x: cx, y: cy)
            let radius = (min(size.width, size.height) - lineWidth) / 2
            let segDeg = 360.0 / Double(max(totalDays, 1))
            let arcDeg = segDeg - gapDeg

            for day in 1...max(totalDays, 1) {
                let startDeg = Double(day - 1) * segDeg - 90.0 + gapDeg / 2
                var path = Path()
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startDeg),
                    endAngle: .degrees(startDeg + arcDeg),
                    clockwise: false
                )
                let isPast  = day <= currentDay
                let isToday = day == currentDay
                let width: CGFloat = isToday ? lineWidth + 3 : lineWidth
                let color = segmentColor(day: day, past: isPast)
                ctx.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: width, lineCap: .butt))
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: currentDay)
    }

    private func segmentColor(day: Int, past: Bool) -> Color {
        let alpha: Double = past ? 1.0 : 0.15
        if day <= menstrualEnd { return colorMenstrual.opacity(alpha) }
        if day >= fertileStart && day <= fertileEnd { return colorFertile.opacity(alpha) }
        if let ov = ovulationCycleDay, day > ov { return colorLuteal.opacity(alpha) }
        return colorFollicular.opacity(alpha)
    }
}

// MARK: - CycleProgressWidget

struct CycleProgressWidget: View {
    let prediction: Prediction?
    let currentDay: Int

    private static let isoFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate]; return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Anneau segmenté jours du cycle
                SegmentedCycleRing(
                    totalDays: cycleLength,
                    currentDay: currentDay,
                    menstrualEnd: 5,
                    fertileStart: fertileStartDay,
                    fertileEnd: fertileEndDay,
                    ovulationCycleDay: ovulationCycleDay
                )

                // Texte central
                VStack(spacing: 4) {
                    Text("cycle_day_label \(currentDay)")
                        .font(.title2.bold())
                    Text(phaseLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    // MARK: Helpers

    private func daysDiff(to isoString: String) -> Int {
        guard let target = Self.isoFmt.date(from: isoString) else { return 0 }
        return Calendar.current.dateComponents([.day], from: .now, to: target).day ?? 0
    }

    private var cycleLength: Int {
        guard let p = prediction else { return 28 }
        return max(currentDay + max(daysUntilNext(p), 1), 20)
    }

    private var fertileStartDay: Int {
        guard let p = prediction else { return 10 }
        return max(currentDay + daysDiff(to: p.fertileWindowStart), 1)
    }

    private var fertileEndDay: Int {
        guard let p = prediction else { return 16 }
        return max(currentDay + daysDiff(to: p.fertileWindowEnd), fertileStartDay)
    }

    private var ovulationCycleDay: Int? {
        guard let p = prediction, let ov = p.ovulationDay else { return nil }
        let d = currentDay + daysDiff(to: ov)
        return d > 0 ? d : nil
    }

    private var phaseLabel: String {
        guard let p = prediction else { return "" }
        let days = daysUntilNext(p)
        if currentDay <= 5 { return NSLocalizedString("phase_menstrual", comment: "") }
        if currentDay >= fertileStartDay && currentDay <= fertileEndDay {
            return NSLocalizedString("phase_ovulatory", comment: "")
        }
        if days < 14 { return NSLocalizedString("phase_luteal", comment: "") }
        return NSLocalizedString("phase_follicular", comment: "")
    }

    private var accessibilityDescription: String {
        guard let p = prediction else {
            return NSLocalizedString("cycle_no_data_a11y", comment: "")
        }
        return String(format: NSLocalizedString("cycle_progress_a11y", comment: ""),
                      currentDay, daysUntilNext(p))
    }

    private func daysUntilNext(_ p: Prediction) -> Int {
        daysDiff(to: p.nextPeriodStart)
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
