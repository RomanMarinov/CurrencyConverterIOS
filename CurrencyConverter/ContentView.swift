//
//  ContentView.swift
//  CurrencyConverter
//
//  Created by Роман Маринов on 12.04.2026.
//

import SwiftUI

/// Canvas / legacy entry; the app uses `RootTabView` from `CurrencyConverterApp`.
struct ContentView: View {
    var body: some View {
        RootTabView()
            .environment(AppCompositionRoot.makeRatesStore())
            .environment(\.preferences, UserPreferences())
    }
}

#Preview {
    ContentView()
}
