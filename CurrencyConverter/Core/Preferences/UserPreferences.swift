import Foundation
import SwiftUI

private enum PreferencesKey: EnvironmentKey {
    static let defaultValue = UserPreferences()
}

extension EnvironmentValues {
    var preferences: UserPreferences {
        get { self[PreferencesKey.self] }
        set { self[PreferencesKey.self] = newValue }
    }
}

final class UserPreferences: @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var leftCurrencyCode: String {
        get { Self.normalizeRuble(defaults.string(forKey: Keys.leftCurrency) ?? "RUB") }
        set { defaults.set(newValue, forKey: Keys.leftCurrency) }
    }

    var rightCurrencyCode: String {
        get { Self.normalizeRuble(defaults.string(forKey: Keys.rightCurrency) ?? "USD") }
        set { defaults.set(newValue, forKey: Keys.rightCurrency) }
    }

    private static func normalizeRuble(_ code: String) -> String {
        code.uppercased() == "RUR" ? "RUB" : code.uppercased()
    }

    var leftAmountText: String {
        get { defaults.string(forKey: Keys.leftAmount) ?? "1" }
        set { defaults.set(newValue, forKey: Keys.leftAmount) }
    }

    var rightAmountText: String {
        get { defaults.string(forKey: Keys.rightAmount) ?? "" }
        set { defaults.set(newValue, forKey: Keys.rightAmount) }
    }

    /// Number of digits after decimal separator for converted values (1...6).
    var fractionDigits: Int {
        get {
            let v = defaults.integer(forKey: Keys.fractionDigits)
            if v == 0 { return 2 }
            return min(max(v, 1), 6)
        }
        set { defaults.set(min(max(newValue, 1), 6), forKey: Keys.fractionDigits) }
    }

    private enum Keys {
        static let leftCurrency = "sharedPrefCharNameLeft"
        static let rightCurrency = "sharedPrefCharNameRight"
        static let leftAmount = "sharedPrefPriceLeft"
        static let rightAmount = "sharedPrefPriceRight"
        static let fractionDigits = "settingsFractionDigits"
    }
}
