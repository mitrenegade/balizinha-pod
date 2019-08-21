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
}
