//
//  Membership.swift
//  Balizinha
//
//  Created by Bobby Ren on 6/27/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

public struct Membership {
    public enum Status: String {
        case organizer
        case member
        case none
    }
    
    public let playerId: String
    public let status: Status
    
    public init(id: String, status: String) {
        playerId = id
        self.status = Status(rawValue: status) ?? .none
    }
    
    public var isActive: Bool { // returns if member OR organizer
        return status != .none
    }
    public var isOrganizer: Bool {
        return status == .organizer
    }
}
