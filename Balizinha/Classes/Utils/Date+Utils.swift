//
//  Date+Utils.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension Date {
    public enum Month: String {
        case Jan
        case Feb
        case Mar
        case Apr
        case May
        case Jun
        case Jul
        case Aug
        case Sep
        case Oct
        case Nov
        case Dec
    }
    
    public static let months: [Date.Month] = [.Jan, .Feb, .Mar, .Apr, .May, .Jun, .Jul, .Aug, .Sep, .Oct, .Nov, .Dec]

    public enum Recurrence: String {
        case none
        case daily
        case weekly
        case monthly
    }

    public func dateString() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        return "\(day) \(Date.months[month - 1]) \(year)"
    }
    
    // date picker
    public func dateStringForPicker() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM dd"
        //dateFormatter.dateStyle = DateFormatter.Style.medium
        //dateFormatter.timeStyle = DateFormatter.Style.none
        return dateFormatter.string(from: self)
    }
    
    // start and end time picker
    public func timeStringForPicker() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter.string(from: self)
    }
    
    // Gets the next recurrence of a date
    public func getNextRecurrence(recurrence: Recurrence = .none, from reference: Date) -> Date? {
        guard reference >  self else { return self }

        var nextDate: Date? = nil
        let calendar = Calendar.current
        var refComponents = calendar.dateComponents([.month, .day], from: reference)
        var eventComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        switch recurrence {
        case .none:
            return self
        case .daily:
            guard let day = refComponents.day else { return nil }
            eventComponents.day = day
            if let date = calendar.date(from: eventComponents), date > reference {
                nextDate = date
            } else {
                eventComponents.day = day + 1
                nextDate = calendar.date(from: eventComponents)
            }
        case .weekly:
            // brute force but the best way to do it!
            var next = self
            while reference > next {
                next = next.addingTimeInterval(7*24*3600)
            }
            nextDate = next
        case .monthly:
            guard let month = refComponents.month else { return nil }
            eventComponents.month = month
            if let date = calendar.date(from: eventComponents), date > reference {
                nextDate = date
            } else {
                eventComponents.month = month + 1
                nextDate = calendar.date(from: eventComponents)
            }
        }
        return nextDate
    }
}
