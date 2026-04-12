//
//  CurrencyConverterTests.swift
//  CurrencyConverterTests
//
//  Created by Роман Маринов on 12.04.2026.
//

import XCTest
@testable import CurrencyConverter

final class CurrencyConverterTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConversionThroughRubBaseline() throws {
        let rub = CurrencyRate.rubBaseline
        let usd = CurrencyRate(code: "USD", name: "US Dollar", rubPerUnit: 90)
        let eur = CurrencyRate(code: "EUR", name: "Euro", rubPerUnit: 100)
        let map = [rub.code: rub, usd.code: usd, eur.code: eur]

        let oneUSDinEUR = AmountConverter.convert(amount: 1, from: "USD", to: "EUR", ratesByCode: map)
        XCTAssertEqual(NSDecimalNumber(decimal: oneUSDinEUR ?? 0).doubleValue, 0.9, accuracy: 0.000_001)

        let tenEURinUSD = AmountConverter.convert(amount: 10, from: "EUR", to: "USD", ratesByCode: map)
        XCTAssertEqual(NSDecimalNumber(decimal: tenEURinUSD ?? 0).doubleValue, 100 / 9, accuracy: 0.000_001)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
