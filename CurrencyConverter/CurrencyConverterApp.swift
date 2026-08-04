//
//  CurrencyConverterApp.swift
//  CurrencyConverter
//
//  Created by Роман Маринов on 12.04.2026.
//

import SwiftUI

@main
struct CurrencyConverterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var ratesStore: RatesStore
    @State private var preferences = UserPreferences()

    init() {
        _ratesStore = State(initialValue: AppCompositionRoot.makeRatesStore())
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(ratesStore)
                .environment(\.preferences, preferences)
                .task {
                    NotificationCoordinator.shared.bindRatesRefresh { @MainActor in
                        await ratesStore.refresh()
                    }
                    NotificationCoordinator.shared.setOnRequestProcessing {
                        processPendingDailyReminderRefresh()
                    }
                    if DailyReminderService.isEnabled {
                        await DailyReminderService.reschedule()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    processPendingDailyReminderRefresh()
                }
        }
    }

    @MainActor
    private func processPendingDailyReminderRefresh() {
        Task { @MainActor in
            await Task.yield()
            await NotificationCoordinator.shared.processPendingDailyReminderIfReady()
        }
    }
}
