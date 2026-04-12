import Foundation

enum AmountConverter {
    static func convert(
        amount: Decimal,
        from fromCode: String,
        to toCode: String,
        ratesByCode: [String: CurrencyRate]
    ) -> Decimal? {
        guard let from = ratesByCode[fromCode], let to = ratesByCode[toCode] else { return nil }
        guard to.rubPerUnit != 0 else { return nil }
        let rub = amount * from.rubPerUnit
        return rub / to.rubPerUnit
    }
}
