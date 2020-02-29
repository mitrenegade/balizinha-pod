//
//  CityHelperTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 2/29/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import Balizinha

class CityHelperTests: XCTestCase {
    func testValidateCityString() {
        let helper = CityHelper()
        XCTAssert(helper.validateCityString("Boston"))
        XCTAssertFalse(helper.validateCityString("Boston, MA"))
        XCTAssertFalse(helper.validateCityString("Boston,MA"))
        XCTAssertFalse(helper.validateCityString("Boston MA"))
        XCTAssertFalse(helper.validateCityString(""))
    }
    
    func testValidateCityStateString() {
        let service = MockCityService()
        let city = City(key: "abc", dict: ["name": "Boston", "state": "MA"])
        service._cities = [city]
        let helper = CityHelper(inputField: UITextField(), delegate: nil, service: service)
        XCTAssertNil(helper.validateCityStateString("Boston"))
        XCTAssertNil(helper.validateCityStateString("Boston MA"))
        XCTAssertNotNil(helper.validateCityStateString("Boston, MA"))
    }
}
