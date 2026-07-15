import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCoordinator()

    private var onDailyReminder: (@MainActor () async -> Void)?
    private var pendingDailyReminderAction = false
    private var onRequestProcessing: (@MainActor () -> Void)?

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        print("[NotificationCoordinator] delegate configured")
    }

    func bindRatesRefresh(_ action: @escaping @MainActor () async -> Void) {
        onDailyReminder = action
        print("[NotificationCoordinator] rates refresh bound")
    }

    func setOnRequestProcessing(_ handler: @escaping @MainActor () -> Void) {
        onRequestProcessing = handler
    }

    func requestProcessingIfReady() {
        onRequestProcessing?()
    }

    func processPendingDailyReminderIfReady() async {
        guard pendingDailyReminderAction else { return }
        guard let onDailyReminder else {
            print("[NotificationCoordinator] pending refresh, waiting for app startup")
            return
        }
        pendingDailyReminderAction = false
        print("[NotificationCoordinator] running rates refresh")
        await onDailyReminder()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        guard id == NotificationConstants.dailyRatesReminderID else {
            completionHandler([])
            return
        }

        Task { @MainActor in
            NotificationCoordinator.shared.markDailyReminderPending(source: "willPresent id=\(id)")
            NotificationCoordinator.shared.requestProcessingIfReady()
            completionHandler([.banner, .sound, .badge])
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        guard id == NotificationConstants.dailyRatesReminderID else {
            completionHandler()
            return
        }

        let action = response.actionIdentifier
        Task { @MainActor in
            NotificationCoordinator.shared.markDailyReminderPending(
                source: "didReceive action=\(action) id=\(id)"
            )
            NotificationCoordinator.shared.requestProcessingIfReady()
            completionHandler()
        }
    }

    private func markDailyReminderPending(source: String) {
        print("[NotificationCoordinator] \(source)")
        pendingDailyReminderAction = true
        print("[NotificationCoordinator] marked pending")
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationCoordinator.shared.configure()
        return true
    }
}
