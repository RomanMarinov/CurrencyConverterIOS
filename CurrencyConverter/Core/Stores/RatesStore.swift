import Foundation
import Observation

@Observable
@MainActor
final class RatesStore {
    private(set) var currencies: [CurrencyRate] = []
    private(set) var ratesByCode: [String: CurrencyRate] = [:]
    private(set) var lastUpdatedISO: String?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private let service: CBRService

    init(service: CBRService = CBRService()) {
        self.service = service
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let payload = try await service.fetchDailyRates()
            lastUpdatedISO = payload.dateISO8601
            currencies = payload.currencies
            ratesByCode = Dictionary(uniqueKeysWithValues: payload.currencies.map { ($0.code, $0) })
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
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
