//
//  EventTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 8/7/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import RenderCloud
@testable import Balizinha

class EventTests: XCTestCase {
    var event: Event!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        event = Event(key: "123", dict: ["organizerId": "456"])
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        event = nil
    }

    func testUserIsOrganizer() {
        XCTAssertTrue(event.userIsOrganizer("456"))
        XCTAssertFalse(event.userIsOrganizer("789"))
        XCTAssertFalse(event.userIsOrganizer(nil))
    }
}
