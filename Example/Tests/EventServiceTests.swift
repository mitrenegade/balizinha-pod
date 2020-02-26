//
//  EventServiceTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 2/25/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import Balizinha

class EventServiceTests: XCTestCase {
    var service: EventService!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        service = MockService.mockEventService()
        service._usersForEvents = ["a": ["1": true, "2": false]]
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAttendanceForResponse() {
        let eventId = "a"
        XCTAssertTrue(service.attendance(for: eventId).contains("1"))
        XCTAssertTrue(service.attendance(for: eventId).contains("2"))
    }

    func testOptOutPlayers() {
        let eventId = "a"
        XCTAssertFalse(service.attendance(for: eventId, attending: false).contains("1"))
        XCTAssertTrue(service.attendance(for: eventId, attending: false).contains("2"))
    }

    func testAttendingPlayers() {
        let eventId = "a"
        XCTAssertTrue(service.attendance(for: eventId, attending: true).contains("1"))
        XCTAssertFalse(service.attendance(for: eventId, attending: true).contains("2"))
    }
}
