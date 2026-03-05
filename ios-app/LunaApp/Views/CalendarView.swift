import SwiftUI

// MARK: - CalendarView

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var showLogSheet: Bool = false

    private var calendar: Calendar { .current }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthHeader(displayedMonth: $displayedMonth)
                    .padding(.horizontal)
                    .padding(.top, 8)

                WeekdayHeader()
                    .padding(.horizontal)
                    .padding(.top, 4)

                MonthGridView(
                    month: displayedMonth,
                    selectedDate: $selectedDate,
                    cycleEvents: appState.cycleEvents
                )
                .padding(.horizontal)

                CalendarLegend()
                    .padding()

                Spacer()
            }
            .navigationTitle("tab_calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDate) { date in
                LogSheetView(date: date)
            }
        }
    }
}

// MARK: - MonthHeader

struct MonthHeader: View {
    @Binding var displayedMonth: Date
    private var calendar: Calendar { .current }

    var body: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(Text("previous_month_a11y"))

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(Text("next_month_a11y"))
        }
    }
}

// MARK: - WeekdayHeader

struct WeekdayHeader: View {
    private var calendar: Calendar { .current }

    var body: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true) // Décoratif — l'info est dans les cellules
    }
}

// MARK: - MonthGridView

struct MonthGridView: View {
    let month: Date
    @Binding var selectedDate: Date?
    let cycleEvents: [String: CycleEventType]

    private var calendar: Calendar { .current }
    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        days += range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        return days
    }

    var columns: [GridItem] { Array(repeating: GridItem(.flexible()), count: 7) }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        eventType: eventType(for: date),
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    )
                    .onTapGesture { selectedDate = date }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private func eventType(for date: Date) -> CycleEventType? {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return cycleEvents[fmt.string(from: date)]
    }
}

// MARK: - CalendarDayCell

struct CalendarDayCell: View {
    let date: Date
    let eventType: CycleEventType?
    let isToday: Bool
    let isSelected: Bool
    private var calendar: Calendar { .current }

    var body: some View {
        ZStack {
            cellBackground
            Text(date, format: .dateTime.day())
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }

    @ViewBuilder
    private var cellBackground: some View {
        if isSelected {
            Circle().fill(Color("AccentPrimary"))
        } else if isToday {
            Circle().stroke(Color("AccentPrimary"), lineWidth: 2)
        } else if let ev = eventType {
            Circle().fill(ev.color.opacity(0.25))
        } else {
            Color.clear
        }
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return Color("AccentPrimary") }
        return .primary
    }

    private var accessibilityDescription: Text {
        var desc = date.formatted(.dateTime.weekday(.wide).day().month())
        if let ev = eventType {
            desc += ". \(ev.accessibilityLabel)"
        }
        if isToday { desc += ". Aujourd'hui" }
        return Text(desc)
    }
}

// MARK: - CalendarLegend

struct CalendarLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(CycleEventType.allCases, id: \.self) { event in
                HStack(spacing: 6) {
                    Circle().fill(event.color).frame(width: 10, height: 10)
                    Text(LocalizedStringKey(event.legendKey))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("calendar_legend_a11y"))
    }
}

// MARK: - CycleEventType

enum CycleEventType: CaseIterable {
    case period, fertile, ovulation, logged

    var color: Color {
        switch self {
        case .period:     return Color("AccentPrimary")
        case .fertile:    return Color("AccentSuccess")
        case .ovulation:  return Color("AccentAccent")
        case .logged:     return Color.gray
        }
    }

    var legendKey: String {
        switch self {
        case .period:     return "legend_period"
        case .fertile:    return "legend_fertile"
        case .ovulation:  return "legend_ovulation"
        case .logged:     return "legend_logged"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .period:     return NSLocalizedString("period_phase_a11y", comment: "")
        case .fertile:    return NSLocalizedString("fertile_window_a11y", comment: "")
        case .ovulation:  return NSLocalizedString("ovulation_day_a11y", comment: "")
        case .logged:     return NSLocalizedString("data_logged_a11y", comment: "")
        }
    }
}

// MARK: - Date: Identifiable

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
