import SwiftUI
import Charts

// MARK: - InsightsView

struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedArticle: EducationArticle? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Stats cycle ─────────────────────────────────────
                    CycleStatsSection()
                        .padding(.horizontal)

                    // ── Symptômes les plus fréquents ─────────────────────
                    SymptomFrequencySection()
                        .padding(.horizontal)

                    // ── Graphiques de tendance ───────────────────────────
                    TrendChartsSection()
                        .padding(.horizontal)

                    // ── Insight auto-généré ──────────────────────────────
                    InsightCardView()
                        .padding(.horizontal)

                    // ── Fiches éducatives ────────────────────────────────
                    EducationSection(selectedArticle: $selectedArticle)
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("tab_insights")
            .sheet(item: $selectedArticle) { article in
                EducationArticleView(article: article)
            }
        }
    }
}

// MARK: - CycleStatsSection

struct CycleStatsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("stats_section_title")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                StatCard(
                    value: appState.averageCycleLength.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "stats_days",
                    label: "stats_avg_cycle",
                    icon: "arrow.triangle.2.circlepath"
                )
                StatCard(
                    value: appState.averagePeriodLength.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "stats_days",
                    label: "stats_avg_period",
                    icon: "drop.fill"
                )
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentPrimary"))
                .font(.title3)
                .accessibilityHidden(true)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(LocalizedStringKey(unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(Text(LocalizedStringKey(label))): \(value) \(Text(LocalizedStringKey(unit)))"))
    }
}

// MARK: - TrendChartsSection

struct TrendChartsSection: View {
    @EnvironmentObject var appState: AppState

    // Sample data — à connecter à LunaEngine get_logs_range
    private var cycleLengths: [(Int, Int)] {
        // (cycle number, length in days) — derniers 6 cycles
        [(1,28),(2,30),(3,27),(4,29),(5,28),(6,31)]
    }

    private var bbtData: [(String, Double)] {
        // (date label, temp) — derniers 14 jours
        let base = 36.5
        let offsets: [Double] = [0.05, -0.08, 0.12, -0.03, 0.07, -0.10, 0.02,
                                  0.28, 0.35, 0.22, 0.40, 0.31, 0.27, 0.38]
        return (0..<14).map { i in
            ("J\(i+1)", base + (i < 7 ? 0.0 : 0.3) + offsets[i])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("charts_section_title")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            // Durées des cycles — graphique en barres
            VStack(alignment: .leading, spacing: 8) {
                Text("charts_cycle_lengths")
                    .font(.subheadline.bold())

                Chart(cycleLengths, id: \.0) { cycle, length in
                    BarMark(
                        x: .value("charts_cycle_num", "C\(cycle)"),
                        y: .value("charts_days", length)
                    )
                    .foregroundStyle(Color("AccentPrimary"))
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks(values: [21, 28, 35]) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .accessibilityLabel(Text("charts_cycle_lengths_a11y"))
            }
            .padding(16)
            .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))

            // Température basale — courbe
            VStack(alignment: .leading, spacing: 8) {
                Text("charts_bbt_title")
                    .font(.subheadline.bold())

                Chart(bbtData, id: \.0) { date, temp in
                    LineMark(
                        x: .value("charts_day", date),
                        y: .value("charts_temp_c", temp)
                    )
                    .foregroundStyle(Color("AccentAccent"))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("charts_day", date),
                        y: .value("charts_temp_c", temp)
                    )
                    .foregroundStyle(Color("AccentAccent"))
                    .symbolSize(20)
                }
                .frame(height: 120)
                .chartYScale(domain: 36.0...37.5)
                .chartXAxis(.hidden)
                .accessibilityLabel(Text("charts_bbt_a11y"))
            }
            .padding(16)
            .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - SymptomFrequencySection

struct SymptomFrequencySection: View {
    // Données de démonstration — à connecter à LunaEngine
    private let topSymptoms: [(String, Double)] = [
        ("cramps", 0.85),
        ("fatigue", 0.70),
        ("bloating", 0.55),
        ("headache", 0.40),
        ("breast_tenderness", 0.35),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("symptoms_stats_title")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(topSymptoms, id: \.0) { (symptom, freq) in
                    SymptomFrequencyRow(symptom: symptom, frequency: freq)
                }
            }
            .padding(16)
            .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SymptomFrequencyRow: View {
    let symptom: String
    let frequency: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(NSLocalizedString("symptom_\(symptom)", comment: "Symptom name"))
                .font(.subheadline)
                .frame(width: 130, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(Color("AccentPrimary").opacity(0.7))
                        .frame(width: geo.size.width * frequency)
                }
            }
            .frame(height: 8)

            Text("\(Int(frequency * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(NSLocalizedString("symptom_\(symptom)", comment: "Symptom name")): \(Int(frequency * 100))%")
        )
    }
}

// MARK: - InsightCardView

struct InsightCardView: View {
    // TODO: brancher sur LunaEngine insights
    private let sampleInsight = "insight_sample_luteal_cramps"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color("AccentAccent"))
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("insight_title")
                    .font(.subheadline.bold())
                Text(LocalizedStringKey(sampleInsight))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color("AccentAccent").opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - EducationSection

struct EducationSection: View {
    @Binding var selectedArticle: EducationArticle?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("education_section_title")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(EducationArticle.sampleArticles) { article in
                    Button {
                        selectedArticle = article
                    } label: {
                        EducationArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct EducationArticleRow: View {
    let article: EducationArticle

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(article.titleKey))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(article.categoryKey))
                    .font(.caption)
                    .foregroundStyle(Color("AccentPrimary"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
        .frame(minHeight: 44) // a11y target
    }
}

// MARK: - EducationArticle

struct EducationArticle: Identifiable {
    let id: String
    let titleKey: String
    let categoryKey: String
    let bodyKey: String

    static let sampleArticles: [EducationArticle] = [
        EducationArticle(id: "pms", titleKey: "article_pms_title", categoryKey: "article_cat_cycle", bodyKey: "article_pms_body"),
        EducationArticle(id: "ovulation", titleKey: "article_ovulation_title", categoryKey: "article_cat_fertility", bodyKey: "article_ovulation_body"),
        EducationArticle(id: "bbt", titleKey: "article_bbt_title", categoryKey: "article_cat_biometrics", bodyKey: "article_bbt_body"),
        EducationArticle(id: "perimenopause", titleKey: "article_perimenopause_title", categoryKey: "article_cat_cycle", bodyKey: "article_perimenopause_body"),
    ]
}

// MARK: - EducationArticleView

struct EducationArticleView: View {
    let article: EducationArticle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(LocalizedStringKey(article.bodyKey))
                    .padding()
            }
            .navigationTitle(LocalizedStringKey(article.titleKey))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("cancel_button") { dismiss() }
                }
            }
        }
    }
}
