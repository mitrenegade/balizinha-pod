//
//  FeedItem.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/29/18.
//

import UIKit

public enum FeedItemType: String {
    case chat
    case photo
    case other
}
public class FeedItem: FirebaseBaseModel {
    public var type: FeedItemType {
        get {
            if let typeString = self.dict["type"] as? String, let type = FeedItemType(rawValue: typeString) {
                return type
            }
            return .other
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var userId: String? {
        get {
            return self.dict["user"] as? String
        }
        set {
            self.dict["user"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    public var leagueId: String? {
        get {
            return self.dict["leagueId"] as? String
        }
        set {
            self.dict["leagueId"] = newValue
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
    
    // generic string to display for backwards compatibility
    let GENERIC_FEED_MESSAGE = ""
    public var defaultMessage: String {
        return self.dict["defaultMessage"] as? String ?? GENERIC_FEED_MESSAGE
    }
}

public extension FeedItem {
    public var hasPhoto: Bool {
        return type == .photo
    }
}
