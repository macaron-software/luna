import Foundation
import UserNotifications

/// Gestionnaire des notifications locales LUNA.
/// Aucune donnée transmise hors device — tout est calculé localement.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Period Reminder (J-2)

    func schedulePeriodReminder(nextPeriodDate: Date) {
        cancelAll(ofCategory: "period_reminder")
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -2, to: nextPeriodDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_period_title", comment: "")
        content.body  = NSLocalizedString("notif_period_body", comment: "")
        content.sound = .default
        content.categoryIdentifier = "period_reminder"

        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "luna_period_\(triggerDate.timeIntervalSince1970)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Fertile Window Alert

    func scheduleFertileWindowAlert(fertileStart: Date) {
        cancelAll(ofCategory: "fertile_alert")

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_fertile_title", comment: "")
        content.body  = NSLocalizedString("notif_fertile_body", comment: "")
        content.sound = .default
        content.categoryIdentifier = "fertile_alert"

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fertileStart)
        components.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "luna_fertile_\(fertileStart.timeIntervalSince1970)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Pill Reminder (daily)

    func schedulePillReminder(timeString: String) {
        cancelAll(ofCategory: "pill_reminder")
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_pill_title", comment: "")
        content.body  = NSLocalizedString("notif_pill_body", comment: "")
        content.sound = .default
        content.categoryIdentifier = "pill_reminder"

        var components = DateComponents()
        components.hour   = parts[0]
        components.minute = parts[1]
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "luna_pill_daily",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel helpers

    func cancelPillReminder() {
        cancelAll(ofCategory: "pill_reminder")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["luna_pill_daily"])
    }

    private func cancelAll(ofCategory category: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == category }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
