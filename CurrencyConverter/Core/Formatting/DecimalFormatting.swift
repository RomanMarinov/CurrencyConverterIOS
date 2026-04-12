import Foundation

enum DecimalFormatting {
    static func parse(_ text: String) -> Decimal? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let normalized = t.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    static func format(_ value: Decimal, fractionDigits: Int, locale: Locale = .current) -> String {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = fractionDigits
        nf.maximumFractionDigits = fractionDigits
        nf.usesGroupingSeparator = false
        return nf.string(from: value as NSDecimalNumber) ?? ""
    }
}
