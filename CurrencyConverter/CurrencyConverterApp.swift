//
//  CurrencyConverterApp.swift
//  CurrencyConverter
//
//  Created by Роман Маринов on 12.04.2026.
//

import SwiftUI

@main
struct CurrencyConverterApp: App {
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
        }
    }
}
