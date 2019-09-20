//
//  DateUtilsTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 8/21/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import Balizinha

class DateUtilsTests: XCTestCase {
    let calendar = Calendar.current
    var date: Date!

    override func setUp() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        date = calendar.date(from: components)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPastNonRecurrentDate() {
        let referenceDate: Date = date.addingTimeInterval(3600)
        let next = date.getNextRecurrence(recurrence: .none, from: referenceDate)!
        XCTAssertEqual(next, date)
        
        let referenceDate2: Date = date.addingTimeInterval(3*3600)
        let next2 = date.getNextRecurrence(recurrence: .none, from: referenceDate2)!
        XCTAssertEqual(next2, date)
    }
    
    func testFutureDailyRecurrentDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components)!
        let referenceDate: Date = date.addingTimeInterval(-3600)
        
        // daily event is 1 hour away
        let next = date.getNextRecurrence(recurrence: .daily, from: referenceDate)!
        XCTAssertEqual(next, date)
        
        // daily event is 7 days away
        let referenceDate3: Date = date.addingTimeInterval(-7*24*3600)
        let next3 = date.getNextRecurrence(recurrence: .daily, from: referenceDate3)!
        XCTAssertEqual(next3, date)
    }
    
    func testFutureMonthlyRecurringDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components)!
        let referenceDate: Date = date.addingTimeInterval(-3600)
        
        let next = date.getNextRecurrence(recurrence: .monthly, from: referenceDate)!
        XCTAssertEqual(next, date)
        
        // event is a month and half away
        let referenceDate2: Date = date.addingTimeInterval(-45*24*3600)
        let next2 = date.getNextRecurrence(recurrence: .monthly, from: referenceDate2)!
        XCTAssertEqual(next2, date)
    }
    
    func testDailyRecurrentDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components)!
        let referenceDate: Date = date.addingTimeInterval(3600)
        let next = date.getNextRecurrence(recurrence: .daily, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(date), 24*3600)
        
        // reference date is 10 days into the future; event should be 11 days later
        let referenceDate2: Date = date.addingTimeInterval(10*24*3600)
        let next2 = date.getNextRecurrence(recurrence: .daily, from: referenceDate2)!
        XCTAssertEqual(next2.timeIntervalSince(date), 11*24*3600)
    }
    
    func testWeeklyRecurrentDate() {
        let components = DateComponents(year: 2019, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components)!
        let referenceDate: Date = date.addingTimeInterval(3600)
        let next = date.getNextRecurrence(recurrence: .weekly, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(date), 7*24*3600)
        
        let referenceDate2: Date = date.addingTimeInterval(10*24*3600)
        let next2 = date.getNextRecurrence(recurrence: .weekly, from: referenceDate2)!
        let target = date.addingTimeInterval(14*24*3600)
        XCTAssertEqual(next2, target)
    }
    
    func testMonthlyRecurrentDate() {
        // use july 1 to avoid using february
        let components = DateComponents(year: 2019, month: 7, day: 1, hour: 12, minute: 0, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let date: Date = calendar.date(from: components)!
        let referenceDate: Date = date.addingTimeInterval(3600)
        let next = date.getNextRecurrence(recurrence: .monthly, from: referenceDate)!
        XCTAssertEqual(next.timeIntervalSince(date), 31*24*3600)
        
        // reference date is aug 15; event should be sept 1
        let referenceDate2: Date = date.addingTimeInterval(45*24*3600)
        let next2 = date.getNextRecurrence(recurrence: .monthly, from: referenceDate2)!
        XCTAssertEqual(next2.timeIntervalSince(date), 62*24*3600)
    }

    func testDaylightSavingsChanged() {
        let calendar = Calendar(identifier: .gregorian)
        let components1 = DateComponents(year: 2019, month: 3, day: 9, hour: 12, minute: 0, second: 0)
        let date1: Date = calendar.date(from: components1)!
        let components2 = DateComponents(year: 2019, month: 3, day: 11, hour: 12, minute: 0, second: 0)
        let date2: Date = calendar.date(from: components2)!
        XCTAssertTrue(Date.didDaylightSavingsChange(date1, date2))
    }
}
