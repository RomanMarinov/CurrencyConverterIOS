import Foundation

enum CBRServiceError: Error, LocalizedError {
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

struct CBRRatesPayload: Sendable {
    let dateISO8601: String
    let currencies: [CurrencyRate]
}


struct CBRService: Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    nonisolated func fetchDailyRates() async throws -> CBRRatesPayload {
        guard let url = URL(string: "https://www.cbr-xml-daily.ru/daily_json.js") else {
            throw CBRServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CBRServiceError.badStatus(-1) }
        guard (200 ... 299).contains(http.statusCode) else { throw CBRServiceError.badStatus(http.statusCode) }

        let root = try decoder.decode(CBRDailyResponse.self, from: data)
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
        return CBRRatesPayload(dateISO8601: root.date, currencies: list)
    }
}

// MARK: - Private DTOs

private struct CBRDailyResponse: Decodable {
    let date: String
    let valute: [String: CBRValuteDTO]

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case valute = "Valute"
    }
}

private struct CBRValuteDTO: Decodable {
    let charCode: String
    let nominal: Int
    let name: String
    let value: Double

    enum CodingKeys: String, CodingKey {
        case charCode = "CharCode"
        case nominal = "Nominal"
        case name = "Name"
        case value = "Value"
    }
}
