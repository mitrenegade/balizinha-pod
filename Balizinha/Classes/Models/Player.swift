//
//  Player.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore

public class Player: FirebaseBaseModel {
    public enum Platform: String {
        case ios
        case android
    }
    
    public var name: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["name"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "name", value: newValue)
        }
    }
    
    public var email: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["email"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "email", value: newValue)
        }
    }
    
    public var city: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["city"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "city", value: newValue)
        }
    }
    
    public var cityId: String? {
        get {
            return dict?["cityId"] as? String
        }
        set {
            update(key: "cityId", value: newValue)
        }
    }
    
    public var photoUrl: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["photoUrl"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "photoUrl", value: newValue)
        }
    }
    
    public var info: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["info"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "info", value: newValue)
        }
    }
    
    public var isInactive: Bool {
        return false
    }
    
    // MARK: - Preferred Status
    public var promotionId: String? {
        get {
            return self.dict?["promotionId"] as? String
        }
        set {
            update(key: "promotionId", value: newValue)
        }
    }
    
    // MARK: - Push
    public var fcmToken: String? {
        get {
            return self.dict?["fcmToken"] as? String
        }
        set {
            update(key: "fcmToken", value: newValue)
        }
    }
    
    // MARK: - Location
    public var lat: Double? {
        get {
            return self.dict?["lat"] as? Double
        }
        set {
            update(key: "lat", value: newValue)
        }
    }
    
    public var lon: Double? {
        get {
            return self.dict?["lon"] as? Double
        }
        set {
            update(key: "lon", value: newValue)
        }
    }
    
    public var lastLocationTimestamp: Date? {
        get {
            if let val = self.dict["lastLocationTimestamp"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil
        }
        set {
            let interval = newValue?.timeIntervalSince1970
            update(key: "lastLocationTimestamp", value: interval)
        }
    }
    
    public var os: String? {
        get {
            return self.dict["os"] as? String
        }
        set {
            update(key: "os", value: newValue)
        }
    }
    
    public var version: String? {
        get {
            return dict["version"] as? String ?? self.dict["appVersion"] as? String
        }
        set {
            update(key: "version", value: newValue)
        }
    }
    
    public var build: String? {
        get {
            return dict["build"] as? String
        }
        set {
            update(key: "build", value: newValue)
        }
    }
    
    public var notificationsEnabled: Bool {
        get {
            guard let dict = self.dict else { return true }
            if let val = dict["notificationsEnabled"] as? Bool {
                return val
            }
            return true
        }
        set {
            update(key: "notificationsEnabled", value: newValue)
        }
    }
    
    public var baseVenueId: String? {
        get {
            return dict?["baseVenueId"] as? String
        }
        set {
            update(key: "baseVenueId", value: newValue)
        }
    }

    public var lastActiveTimestamp: Date? {
        get {
            if let val = self.dict["lastActiveTimestamp"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil
        }
        set {
            let interval = newValue?.timeIntervalSince1970
            update(key: "lastActiveTimestamp", value: interval)
        }
    }
}

