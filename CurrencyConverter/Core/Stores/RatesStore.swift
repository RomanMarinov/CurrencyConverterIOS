import Foundation
import Observation

/// Слой приложения (presentation state): хранит UI-состояние курсов и вызывает доменные use cases.
@Observable
@MainActor
final class RatesStore {
    private(set) var currencies: [CurrencyRate] = []
    private(set) var ratesByCode: [String: CurrencyRate] = [:]
    private(set) var lastUpdatedISO: String?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private let fetchExchangeRates: FetchExchangeRatesUseCase
    private let convertCurrencyAmount: ConvertCurrencyAmountUseCase

    init(
        fetchExchangeRates: FetchExchangeRatesUseCase,
        convertCurrencyAmount: ConvertCurrencyAmountUseCase
    ) {
        self.fetchExchangeRates = fetchExchangeRates
        self.convertCurrencyAmount = convertCurrencyAmount
    }

    func refresh() async {
        print("[RatesStore] refresh started")
        isLoading = true
        lastError = nil
        defer {
            isLoading = false
            print("[RatesStore] refresh finished")
        }
        do {
            print("[RatesStore] calling fetch exchange rates use case")
            let snapshot = try await fetchExchangeRates.execute()
            lastUpdatedISO = snapshot.dateISO8601
            currencies = snapshot.currencies
            ratesByCode = Dictionary(uniqueKeysWithValues: snapshot.currencies.map { ($0.code, $0) })
            print("[RatesStore] refresh succeeded with \(snapshot.currencies.count) currencies")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            lastError = message
            print("[RatesStore] refresh failed: \(message)")
        }
    }

    /// Делегирует доменному use case; View не импортирует логику конвертации напрямую.
    func convert(amount: Decimal, from fromCode: String, to toCode: String) -> Decimal? {
        convertCurrencyAmount.execute(
            amount: amount,
            from: fromCode,
            to: toCode,
            ratesByCode: ratesByCode
        )
    }

    func displayDateLine(locale: Locale = .current) -> String {
        guard let raw = lastUpdatedISO else { return "" }
        let prefix = String(raw.prefix(10))
        if let date = Self.isoDateFormatter.date(from: prefix) {
            let df = DateFormatter()
            df.locale = locale
            df.dateStyle = .medium
            df.timeStyle = .none
            return "Данные за \(df.string(from: date))"
        }
        return "Данные за \(prefix)"
    }

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f
    }()
}
