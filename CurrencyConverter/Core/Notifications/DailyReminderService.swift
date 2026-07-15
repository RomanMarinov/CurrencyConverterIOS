import Foundation
import UserNotifications

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

    static func persistTime(hour newHour: Int, minute newMinute: Int) {
        hour = newHour
        minute = newMinute
    }

    static func persistTime(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if let h = components.hour, let m = components.minute {
            persistTime(hour: h, minute: m)
        }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("[DailyReminderService] authorization failed: \(error.localizedDescription)")
                return false
            }
        @unknown default:
            return false
        }
    }

    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationConstants.dailyRatesReminderID])

        guard isEnabled else { return }
        guard await requestAuthorizationIfNeeded() else {
            print("[DailyReminderService] notifications not authorized")
            return
        }

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Курсы валют"
        content.body = "Обновите котировки ЦБ или откройте конвертер."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationConstants.dailyRatesReminderID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("[DailyReminderService] scheduled daily reminder at \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("[DailyReminderService] failed to schedule: \(error.localizedDescription)")
        }
    }

    static func statusMessage() async -> String {
        guard isEnabled else { return "" }

        let time = String(format: "%02d:%02d", hour, minute)
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .denied:
            return "Напоминание: \(time) · разрешите уведомления в Настройках iOS"
        case .notDetermined:
            return "Напоминание: \(time) · нужно разрешение на уведомления"
        default:
            break
        }

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if pending.contains(where: { $0.identifier == NotificationConstants.dailyRatesReminderID }) {
            return "Напоминание: \(time) · запланировано в iOS"
        }
        return "Напоминание: \(time) · не удалось запланировать"
    }
}
