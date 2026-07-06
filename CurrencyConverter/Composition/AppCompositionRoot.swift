import Foundation

/// Composition Root: единственное место, где собираются реализации и use cases (Clean Architecture).
enum AppCompositionRoot {
    @MainActor
    static func makeRatesStore() -> RatesStore {
        let repository = CBRExchangeRatesRepository()
        let fetchExchangeRates = FetchExchangeRatesUseCase(repository: repository)
        let convertCurrencyAmount = ConvertCurrencyAmountUseCase()
        return RatesStore(
            fetchExchangeRates: fetchExchangeRates,
            convertCurrencyAmount: convertCurrencyAmount
        )
    }
}
