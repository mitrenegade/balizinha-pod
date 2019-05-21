//
//  City.swift
//  Balizinha
//
//  Created by Bobby Ren on 5/16/19.
//

import Foundation

public class City: FirebaseBaseModel {
    public override convenience init(key: String, dict: [String: Any]?) {
        self.init()
        self.firebaseKey = key
        self.firebaseRef = firRef.child("cities").child(key)
        self.dict = dict ?? [:]
    }
    
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            update(key: "name", value: newValue)
        }
    }
    
    public var state: String? {
        get {
            return self.dict["state"] as? String
        }
        set {
            update(key: "state", value: newValue)
        }
    }
    
    public var lat: Double? {
        get {
            return self.dict["lat"] as? Double
        }
        set {
            update(key: "lat", value: newValue)
        }
    }
    
    public var lon: Double? {
        get {
            return self.dict["lon"] as? Double
        }
        set {
            update(key: "lon", value: newValue)
        }
    }
    
    public var verified: Bool {
        get {
            return self.dict["verified"] as? Bool ?? false
        }
        set {
            update(key: "verified", value: newValue)
        }
    }
}

extension City {
    public var latLonString: String? {
        if let lat = lat, let lon = lon {
            return "\(lat), \(lon)"
        }
        return nil
    }
    
    public var shortString: String? {
        if let name = name {
            if let state = state {
                return "\(name), \(state)"
            } else {
                return name
            }
        }
        return nil
    }
}
