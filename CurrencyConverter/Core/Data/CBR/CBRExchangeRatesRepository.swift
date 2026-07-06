import Foundation

/// Ошибки слоя данных (сеть/парсинг). Домен их не импортирует — при необходимости маппятся в presentation.
enum CBRDataError: Error, LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .badStatus(let code): return "Server returned status \(code)."
        case .decodingFailed: return "Could not parse exchange rates."
        }
    }
}

/// Реализация `ExchangeRatesRepository`: API daily_json ЦБ РФ.
struct CBRExchangeRatesRepository: ExchangeRatesRepository, Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchDailyRates() async throws -> ExchangeRatesSnapshot {
        guard let url = URL(string: "https://www.cbr-xml-daily.ru/daily_json.js") else {
            throw CBRDataError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CBRDataError.badStatus(-1) }
        guard (200 ... 299).contains(http.statusCode) else { throw CBRDataError.badStatus(http.statusCode) }

        let root: CBRDailyResponse
        do {
            root = try decoder.decode(CBRDailyResponse.self, from: data)
        } catch {
            throw CBRDataError.decodingFailed
        }

        var list: [CurrencyRate] = [.rubBaseline]
        list.reserveCapacity(root.valute.count + 1)

        for (_, v) in root.valute {
            let nominal = Decimal(max(v.nominal, 1))
            let value = Decimal(string: String(v.value)) ?? 0
            guard value > 0 else { continue }
            let rubPerUnit = value / nominal
            list.append(CurrencyRate(code: v.charCode, name: v.name, rubPerUnit: rubPerUnit))
        }

        list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return ExchangeRatesSnapshot(dateISO8601: root.date, currencies: list)
    }
}

// MARK: - DTO (только Data-слой, не домен)

private struct CBRDailyResponse: Sendable {
    let date: String
    let valute: [String: CBRValuteDTO]
}

extension CBRDailyResponse: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        valute = try c.decode([String: CBRValuteDTO].self, forKey: .valute)
    }

    private enum CodingKeys: String, CodingKey {
        case date = "Date"
        case valute = "Valute"
    }
}

private struct CBRValuteDTO: Sendable {
    let charCode: String
    let nominal: Int
    let name: String
    let value: Double
}

extension CBRValuteDTO: Decodable {
    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        charCode = try c.decode(String.self, forKey: .charCode)
        nominal = try c.decode(Int.self, forKey: .nominal)
        name = try c.decode(String.self, forKey: .name)
        value = try c.decode(Double.self, forKey: .value)
    }

    private enum CodingKeys: String, CodingKey {
        case charCode = "CharCode"
        case nominal = "Nominal"
        case name = "Name"
        case value = "Value"
    }
}
