//
//  Venue.swift
//  Panna
//
//  Created by Bobby Ren on 8/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

public class Venue: FirebaseBaseModel {
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            update(key: "name", value: newValue)
        }
    }

    public var street: String? {
        get {
            return self.dict["street"] as? String
        }
        set {
            update(key: "street", value: newValue)
        }
    }
    
    public var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            update(key: "city", value: newValue)
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
}

extension Venue {
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
