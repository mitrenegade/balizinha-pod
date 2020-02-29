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
    var helper: CityHelper!
    override func setUp() {
        helper = CityHelper()
    }

    override func tearDown() {
        helper = nil
    }

    func testValidateCityString() {
        XCTAssert(helper.validateCityString("Boston"))
        XCTAssertFalse(helper.validateCityString("Boston, MA"))
        XCTAssertFalse(helper.validateCityString("Boston,MA"))
        XCTAssertFalse(helper.validateCityString("Boston MA"))
        XCTAssertFalse(helper.validateCityString(""))
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
