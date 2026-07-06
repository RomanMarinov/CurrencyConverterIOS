import Foundation

/// Чистая доменная логика пересчёта суммы через курс к рублю (без UI и без сети).
struct ConvertCurrencyAmountUseCase: Sendable {
    func execute(
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
