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
    
    func testEventTime() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components) ?? Date()
        let event = Event(key: "123", dict: ["recurrence": "none"])
        let dateString = event.dateString(date)
        XCTAssertEqual(dateString, "Tue, Jan 01", "Incorrect date: \(dateString)")
    }
    
    func testEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components) ?? Date()
        let event = Event(key: "123", dict: ["recurrence": "none"])
        let timeString = event.timeString(date)
        XCTAssertEqual(timeString, "12:00 PM", "Incorrect time: \(timeString)")
    }
    
    func testRecurringEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components) ?? Date()
        let event = Event(key: "123", dict: ["recurrence": "none"])
        let dateString = event.dateString(date)
        XCTAssertEqual(dateString, "Tue, Jan 01", "Incorrect date: \(dateString)")
    }
    
    func testRecurrence() {
        let none = Event(key: "123", dict: ["recurrence": "none"])
        XCTAssert(none.recurrence == .none)
        let daily = Event(key: "123", dict: ["recurrence": "daily"])
        XCTAssert(daily.recurrence == .daily)
        let weekly = Event(key: "123", dict: ["recurrence": "weekly"])
        XCTAssert(weekly.recurrence == .weekly)
        let monthly = Event(key: "123", dict: ["recurrence": "monthly"])
        XCTAssert(monthly.recurrence == .monthly)
        monthly.recurrence = .weekly
        XCTAssert(monthly.recurrence == .weekly)
    }
    
    // attendance/opt out tests
    func testPlayerIsAttending() {
        let service: EventService = MockService.mockEventService()
        service._usersForEvents = ["a": ["1": true, "2": false]]

        let event = Event(key: "a", dict: nil)
        let player1 = Player(key: "1", dict: nil)
        let player2 = Player(key: "2", dict: nil)
        let player3 = Player(key: "3", dict: nil)
        XCTAssertTrue(event.playerIsAttending(player1, service: service))
        XCTAssertFalse(event.playerIsAttending(player2, service: service))
        XCTAssertFalse(event.playerIsAttending(player3, service: service))
    }

    func testPlayerOptedOut() {
        let service: EventService = MockService.mockEventService()
        service._usersForEvents = ["a": ["1": true, "2": false]]

        let event = Event(key: "a", dict: nil)
        let player1 = Player(key: "1", dict: nil)
        let player2 = Player(key: "2", dict: nil)
        let player3 = Player(key: "3", dict: nil)
        XCTAssertFalse(event.playerOptedOut(player1, service: service))
        XCTAssertTrue(event.playerOptedOut(player2, service: service))
        XCTAssertFalse(event.playerOptedOut(player3, service: service))
    }
}
