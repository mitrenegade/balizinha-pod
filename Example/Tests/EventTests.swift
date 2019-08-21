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
    
    func testPastNonRecurrentEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(3600)
        let event = Event(key: "123", dict: ["recurrence": "none"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next, eventDate)

        let referenceDate2: Date = eventDate.addingTimeInterval(3*3600)
        let next2 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate2)!
        XCTAssertEqual(next2, eventDate)
    }

    func testFutureDailyRecurrentEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(-3600)
        
        // daily event is 1 hour away
        let event = Event(key: "123", dict: ["recurrence": "daily"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next, eventDate)

        // daily event is 7 days away
        let referenceDate3: Date = eventDate.addingTimeInterval(-7*24*3600)
        let next3 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate3)!
        XCTAssertEqual(next3, eventDate)
    }
    
    func testFutureMonthlyRecurringEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(-3600)

        let event = Event(key: "123", dict: ["recurrence": "monthly"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next, eventDate)

        // event is a month and half away
        let referenceDate2: Date = eventDate.addingTimeInterval(-45*24*3600)
        let next2 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate2)!
        XCTAssertEqual(next2, eventDate)
    }

    func testDailyRecurrentEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(3600)
        let event = Event(key: "123", dict: ["recurrence": "daily"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(eventDate), 24*3600)

        // reference date is 10 days into the future; event should be 11 days later
        let referenceDate2: Date = eventDate.addingTimeInterval(10*24*3600)
        let next2 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate2)!
        XCTAssertEqual(next2.timeIntervalSince(eventDate), 11*24*3600)
    }

    func testWeeklyRecurrentEventDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(3600)
        let event = Event(key: "123", dict: ["recurrence": "weekly"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(eventDate), 7*24*3600)

        let referenceDate2: Date = eventDate.addingTimeInterval(10*24*3600)
        let next2 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate2)!
        let target = eventDate.addingTimeInterval(14*24*3600)
        XCTAssertEqual(next2, target)
    }

    func testMonthlyRecurrentEventDate() {
        // use july 1 to avoid using february
        let components = DateComponents(year: 2019, month: 7, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let eventDate: Date = calendar.date(from: components)!
        let referenceDate: Date = eventDate.addingTimeInterval(3600)
        let event = Event(key: "123", dict: ["recurrence": "monthly"])
        let next = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(eventDate), 31*24*3600)

        // reference date is aug 15; event should be sept 1
        let referenceDate2: Date = eventDate.addingTimeInterval(45*24*3600)
        let next2 = event.getNextRecurrence(recurringDate: eventDate, from: referenceDate2)!
        XCTAssertEqual(next2.timeIntervalSince(eventDate), 62*24*3600)
    }

}
