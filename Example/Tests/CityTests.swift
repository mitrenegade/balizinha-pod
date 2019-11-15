//
//  CityTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 11/14/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Balizinha

class CityTests: XCTestCase {
    var city: City!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCityHash (){
        let city = createCity(name: "name", state: "State") // regular
        XCTAssertTrue(city.hashString == "name.state", "hash: \(city.hashString)")
        let city2 = createCity(name: "NAME", state: "STATE") // capitalization
        XCTAssertTrue(city2.hashString == "name.state", "hash: \(city2.hashString)")
        let city3 = createCity(name: "  name  ", state: "  State  ") // spacing
        XCTAssertTrue(city3.hashString == "name.state", "hash: \(city3.hashString)")
    }
    
    func testCityEquality() {
        let city = createCity(name: "name", state: "State")
        let city2 = createCity(name: "NAME", state: "STATE")
        XCTAssert(city == city2)
    }

    func testCityInequality() {
        let city = createCity(name: "name", state: "State")
        let city2 = createCity(name: "name2", state: "State")
        XCTAssertNotEqual(city, city2)
    }

    static var uid: Int = 0
    private func createCity(name: String, state: String) -> City {
        CityTests.uid = CityTests.uid + 1
        return City(key: "\(CityTests.uid)", dict: ["name": name, "state": state])
    }
}
