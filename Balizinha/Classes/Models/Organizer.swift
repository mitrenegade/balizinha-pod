//
//  Organizer.swift
//  Balizinha
//
//  Created by Bobby Ren on 10/2/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore

public enum OrganizerStatus: String, Equatable {
    case none // default, but players who are not organizers won't have an organizer object
    case pending
    case approved // needs payment
    case active
    case trial
}

public func ==(lhs: OrganizerStatus, rhs: OrganizerStatus) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.pending, .pending):
        return true
    case (.approved, .approved):
        return true
    case (.active, .active):
        return true
    case (.trial, .trial):
        return true
    default:
        return false
    }
}

public class Organizer: FirebaseBaseModel {
    public var paymentSourceId: String? {
        guard let dict = self.dict else { return nil }
        return dict["paymentSourceId"] as? String
    }
    
    public var paymentNeeded: Bool {
        get {
            return self.dict?["paymentNeeded"] as? Bool ?? false
        }
        set {
            update(key: "paymentNeeded", value: newValue)
        }
    }

    public var deadline: Double? {
        get {
            return self.dict?["deadline"] as? Double
        }
        set {
            update(key: "deadline", value: newValue)
        }
    }
    
    public var status: OrganizerStatus {
        get {
            if let statusString = self.dict?["status"] as? String, let organizerStatus = OrganizerStatus(rawValue: statusString) {
                return organizerStatus
            }
            return .none
        }
        set {
            update(key: "status", value: newValue)
        }
    }
}
