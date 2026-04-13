import SwiftUI

struct CurrencyPickerSheet: View {
    let currencies: [CurrencyRate]
    let title: String
    let onPick: (CurrencyRate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [CurrencyRate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return currencies }
        return currencies.filter {
            $0.code.localizedCaseInsensitiveContains(q) || $0.name.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { c in
                Button {
                    onPick(c)
                    dismiss()
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(c.code)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 52, alignment: .leading)
                        Text(c.name)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Поиск по коду или названию")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
