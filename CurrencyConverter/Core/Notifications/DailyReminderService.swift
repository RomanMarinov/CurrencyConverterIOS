import Foundation
import UserNotifications

@MainActor
enum DailyReminderService {
    private static let hourKey = "reminderHour"
    private static let minuteKey = "reminderMinute"
    private static let enabledKey = "reminderEnabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var hour: Int {
        get {
            let h = UserDefaults.standard.integer(forKey: hourKey)
            return (0 ... 23).contains(h) ? h : 9
        }
        set { UserDefaults.standard.set(min(max(newValue, 0), 23), forKey: hourKey) }
    }

    static var minute: Int {
        get {
            let m = UserDefaults.standard.integer(forKey: minuteKey)
            return (0 ... 59).contains(m) ? m : 0
        }
        set { UserDefaults.standard.set(min(max(newValue, 0), 59), forKey: minuteKey) }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyRatesReminder"])

        guard isEnabled else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Курсы валют"
        content.body = "Обновите котировки ЦБ или откройте конвертер."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyRatesReminder", content: content, trigger: trigger)
        try? await center.add(request)
    }
}
