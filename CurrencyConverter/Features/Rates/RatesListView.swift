import SwiftUI

struct RatesListView: View {
    @Environment(RatesStore.self) private var store

    @State private var query = ""

    private var filtered: [CurrencyRate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.currencies }
        return store.currencies.filter {
            $0.code.localizedCaseInsensitiveContains(q) || $0.name.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.code)
                            .font(.headline)
                        Spacer()
                        Text(rubLabel(for: c))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(c.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Курсы ЦБ")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Поиск")
            .refreshable {
                await store.refresh()
            }
            .overlay {
                if filtered.isEmpty, !store.isLoading {
                    ContentUnavailableView(
                        "Нет данных",
                        systemImage: "wifi.slash",
                        description: Text(store.lastError ?? "Потяните вниз для обновления.")
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !store.displayDateLine().isEmpty {
                    Text(store.displayDateLine())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .task {
            if store.currencies.isEmpty {
                await store.refresh()
            }
        }
    }

    private func rubLabel(for c: CurrencyRate) -> String {
        if c.code == "RUB" {
            return "база"
        }
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 4
        nf.minimumFractionDigits = 2
        nf.locale = .current
        let v = c.rubPerUnit as NSDecimalNumber
        let s = nf.string(from: v) ?? "—"
        return "\(s) ₽ / 1 \(c.code)"
    }
}
