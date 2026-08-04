import Foundation

struct CurrencyRate: Identifiable, Equatable, Hashable, Sendable {
    var id: String { code }

    let code: String
    let name: String
    let rubPerUnit: Decimal

    nonisolated static let rubBaseline = CurrencyRate(code: "RUB", name: "Российский рубль", rubPerUnit: 1)
}
