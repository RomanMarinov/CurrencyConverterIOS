import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ConvertView()
                .tabItem {
                    Label("Конвертер", systemImage: "arrow.left.arrow.right.circle")
                }

            RatesListView()
                .tabItem {
                    Label("Курсы", systemImage: "list.bullet.rectangle")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.accent)
        .ratesRefreshToast()
    }
}
