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
class FeedItem: FirebaseBaseModel {
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
    
    public var photoId: String? {
        get {
            return self.dict["photoId"] as? String
        }
        set {
            self.dict["photoId"] = newValue
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
    public var defaultMessage: String {
        return self.dict["defaultMessage"] as? String ?? GENERIC_CHAT
    }
}
