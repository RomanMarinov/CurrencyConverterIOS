import Foundation

/// Результат загрузки курсов: доменная модель, не привязанная к API ЦБ.
struct ExchangeRatesSnapshot: Equatable, Sendable {
    let dateISO8601: String
    let currencies: [CurrencyRate]
}
