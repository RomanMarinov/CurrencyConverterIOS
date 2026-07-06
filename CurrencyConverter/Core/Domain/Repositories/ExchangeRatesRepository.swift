import Foundation

/// Абстракция источника курсов. Домен зависит только от протокола; реализация — в Data.
protocol ExchangeRatesRepository: Sendable {
    func fetchDailyRates() async throws -> ExchangeRatesSnapshot
}
