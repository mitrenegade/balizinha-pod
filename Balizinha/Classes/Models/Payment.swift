//
//  Payment.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/26/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

public class Payment: FirebaseBaseModel {
    public var amount: NSNumber? {
        return self.dict["amount"] as? NSNumber
    }

    public var refunded: NSNumber? {
        return self.dict["amount_refunded"] as? NSNumber
    }
    
    public var paid: Bool {
        return self.dict["paid"] as? Bool ?? false
    }
    
    public var amountString: String? {
        guard let number = amount else { return nil }
        return currencyFormatter.string(from: NSNumber(value: number.doubleValue / 100) )
    }
    
    public var playerId: String? {
        return self.dict["player_id"] as? String
    }
    
    public enum Status: String {
        case succeeded
        case error
        case active // subscription
        case partialRefund
        case refunded
        case unknown
    }

    public var status: Payment.Status {
        guard let string = self.dict["status"] as? String else {
            if error != nil {
                return .error
            }
            return .unknown
        }
        if let refunded = refunded, refunded.doubleValue > 0 {
            return (refunded == amount) ? .refunded : .partialRefund
        }
        guard let newStatus = Status(rawValue: string) else { return .unknown }
        return newStatus
    }
    
    public var error: String? {
        return self.dict["error"] as? String
    }

    fileprivate var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.currencyDecimalSeparator = "."
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
    
    override public var createdAt: Date? {
        if let val = self.dict["created"] as? TimeInterval {
            let time1970: TimeInterval = 1517606802
            if val > time1970 * 10.0 {
                return Date(timeIntervalSince1970: (val / 1000.0))
            } else {
                return Date(timeIntervalSince1970: val)
            }
        }
        return nil
    }
}
