//
//  Venue.swift
//  Panna
//
//  Created by Bobby Ren on 8/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

public class Venue: FirebaseBaseModel {
    public enum SpaceType: String, CustomStringConvertible, CaseIterable {
        case unknown
        case grass
        case turf
        case wood
        case concrete
        case mats
        case rubber
        case remote
        case other
        
        public var description: String {
            return rawValue.capitalized
        }
    }
    public var name: String? {
        get {
            return dict["name"] as? String
        }
        set {
            update(key: "name", value: newValue)
        }
    }
    
    public var type: SpaceType {
        get {
            if let space = dict["type"] as? String {
                return SpaceType(rawValue: space) ?? .unknown
            }
            return .unknown
        }
        set {
            update(key: "type", value: newValue.rawValue)
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
    
//    public var cityId: String? {
//        get {
//            return dict["cityId"] as? String
//        }
//        set {
//            update(key: "cityId", value: newValue)
//        }
//    }
    
    // placeholder: may be google or apple
    public var placeId: String? {
        get {
            return dict["placeId"] as? String
        }
        set {
            update(key: "placeId", value: newValue)
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
    
    public var photoUrl: String? {
        get {
            if let val = dict["photoUrl"] as? String {
                return val
            }
            return nil
        }
        set {
            update(key: "photoUrl", value: newValue)
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
    
    public var typeString: String {
        if self.type == .unknown {
            return (dict["type"] as? String ?? "\(self.type)").capitalized
        }
        return "\(self.type)"
    }

    public var shortString: String {
        if isRemote {
            return "Location: Remote"
        }
        if let city = city {
            if let state = state {
                return "\(city), \(state)"
            } else {
                return city
            }
        }
        return ""
    }
    
    public var isRemote: Bool {
        return type == .remote
    }
}
