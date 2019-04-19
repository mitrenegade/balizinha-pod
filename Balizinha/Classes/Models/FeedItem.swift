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
    case action
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
            update(key: "type", value: newValue)
        }
    }
    
    public var userId: String? {
        get {
            return self.dict["userId"] as? String
        }
        set {
            update(key: "userId", value: newValue)
        }
    }

    public var leagueId: String? {
        get {
            return self.dict["leagueId"] as? String
        }
        set {
            update(key: "leagueId", value: newValue)
        }
    }
    
    public var actionId: String? {
        get {
            return self.dict["actionId"] as? String
        }
    }

    public var message: String? {
        get {
            return self.dict["message"] as? String
        }
        set {
            update(key: "message", value: newValue)
        }
    }
    
    public var visible: Bool { // whether an action should appear in the feed
        get {
            return self.dict["visible"] as? Bool ?? true
        }
        set {
            update(key: "visible", value: newValue)
        }
    }
    
    // generic string to display for backwards compatibility
    let GENERIC_FEED_MESSAGE = "..."
    let GENERIC_PHOTO_MESSAGE = "posted an image"
    public var defaultMessage: String {
        return self.dict["defaultMessage"] as? String ?? (hasPhoto ? GENERIC_PHOTO_MESSAGE : GENERIC_FEED_MESSAGE)
    }
    
    public var userCreatedFeedItem: Bool {
        guard let userId = self.userId else { return false }
        guard let currentUserId = AuthService.currentUser?.uid else { return false }
        
        return currentUserId == userId // TODO: if actions created by events also show up as feed items, filter them out
    }
}

public extension FeedItem {
    var hasPhoto: Bool {
        return type == .photo
    }
}
