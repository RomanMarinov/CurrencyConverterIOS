import Foundation

/// Сценарий приложения: получить актуальный снимок курсов из любого подключённого репозитория.
struct FetchExchangeRatesUseCase: Sendable {
    private let repository: ExchangeRatesRepository

    init(repository: ExchangeRatesRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExchangeRatesSnapshot {
        try await repository.fetchDailyRates()
    }
}
