//
//  Action.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

public enum ActionType: String {
    case chat
    case createEvent
    case joinEvent
    case leaveEvent
    case addedToEvent
    case removedFromEvent
    case joinLeague
    case leaveLeague
    case holdPaymentForEvent
    case payForEvent
    case systemMessage
}

fileprivate let GENERIC_CHAT = "..."
fileprivate let GENERIC_USERNAME = "A player"

public class Action: FirebaseBaseModel {
    public var type: ActionType {
        get {
            if let typeString = self.dict["type"] as? String, let actionType = ActionType(rawValue: typeString) {
                return actionType
            }
            return .systemMessage
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var userId: String? {
        // if user is nil, then it should be a system message
        get {
            return self.dict["userId"] as? String ?? self.dict["user"] as? String
        }
        set {
            self.dict["userId"] = newValue
            self.dict["user"] = newValue // legacy
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var username: String? {
        // makes it easier to generate displayString
        get {
            return self.dict["username"] as? String
        }
        set {
            self.dict["username"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var eventId: String? { // if an action is directly related to an event
        get {
            return self.dict["eventId"] as? String ?? self.dict["event"] as? String
        }
        set {
            self.dict["event"] = newValue // legacy
            self.dict["eventId"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    public var message: String? {
        get {
            return self.dict["message"] as? String
        }
        set {
            self.dict["message"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var visible: Bool { // whether an action should appear in the feed
        get {
            return self.dict["visible"] as? Bool ?? true
        }
        set {
            self.dict["visible"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var defaultMessage: String {
        return self.dict["defaultMessage"] as? String ?? GENERIC_CHAT
    }
}

public class ActionViewModel {
    var action: Action
    var event: Event?

    public init(action: Action) {
        self.action = action
        switch action.type {
        case .createEvent, .joinEvent, .leaveEvent, .payForEvent:
            if let eventId = action.eventId {
                EventService.shared.withId(id: eventId, completion: { [weak self] (event) in
                    self?.event = event
                })
            }
        default:
            return
        }
    }
    
    public var displayDate: String {
        if let date = action.createdAt {
            return date.dateString()
        }
        return "65 Billion BC"
    }
    
    public var eventName: String {
        if let eventId = action.eventId, let foundEvent = EventService.shared.eventForAction(with: eventId) {
            return foundEvent.name ?? "an event"
        }
        return event?.name ?? "an event"
    }
    
    public var displayString: String {
        let userString = userPerformedAction ? "You" : (action.username ?? GENERIC_USERNAME)
        switch action.type {
        case .chat:
            return userString + " said: " + (action.message ?? GENERIC_CHAT)
        case .createEvent:
            return userString + " created \(eventName) at " + self.displayDate
        case .joinEvent:
            return userString + " joined \(eventName)"
        case .leaveEvent:
            return userString + " left \(eventName)"
        case .addedToEvent:
            return userString + " was added to \(eventName)"
        case .removedFromEvent:
            return userString + " was removed from \(eventName)"
        case .joinLeague: // TODO: separate event actions and league actions
            return userString + " joined the league"
        case .leaveLeague:
            return userString + " left the league"
        case .holdPaymentForEvent:
            return userString + " reserved a spot"
        case .payForEvent:
            return userString + " paid for \(eventName)"
        default:
            // system message
            return action.defaultMessage
        }
    }
    
    public var userPerformedAction: Bool {
        guard let userId = self.action.userId else { return false }
        guard let currentUserId = AuthService.currentUser?.uid else { return false }
        
        return currentUserId == userId
    }
}
