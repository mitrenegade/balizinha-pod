//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore

public enum EventType: String {
    case event3v3 = "3 vs 3"
    case event5v5 = "5 vs 5"
    case event7v7 = "7 vs 7"
    case event11v11 = "11 vs 11"
    case group = "Group class"
    case social = "Social event"
    case other
}

fileprivate let formatter = DateFormatter()

public class Event: FirebaseBaseModel {
    public override convenience init(key: String, dict: [String: Any]?) {
        self.init()
        self.firebaseKey = key
        self.firebaseRef = firRef.child("events").child(key)
        self.dict = dict ?? [:]
    }

    public var league: String? {
        get {
            return self.dict["league"] as? String
        }
        set {
            self.dict["league"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var type: EventType {
        get {
            if let string = self.dict["type"] as? String, let newType = EventType(rawValue: string) {
                return newType
            }
            return .other
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    public var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var state: String? {
        get {
            return self.dict["state"] as? String
        }
        set {
            self.dict["state"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var place: String? {
        get {
            return self.dict["place"] as? String
        }
        set {
            self.dict["place"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var lat: Double? {
        get {
            return self.dict["lat"] as? Double
        }
        set {
            self.dict["lat"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var lon: Double? {
        get {
            return self.dict["lon"] as? Double
        }
        set {
            self.dict["lon"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var startTime: Date? {
        get {
            if let val = self.dict["startTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["startTime"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var endTime: Date? {
        get {
            if let val = self.dict["endTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["endTime"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    public var maxPlayers: Int {
        get {
            if let val = self.dict["maxPlayers"] as? UInt {
                return Int(val)
            }
            else if let val = self.dict["max_players"] as? UInt { // backwards compatibility
                return Int(val)
            }
            return 0
        }
        set {
            self.dict["maxPlayers"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
    
    public var info: String {
        get {
            if let val = self.dict["info"] as? String {
                return val
            }
            return ""
        }
        set {
            self.dict["info"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var paymentRequired: Bool {
        if let paymentRequired = self.dict["paymentRequired"] as? Bool {
            return paymentRequired
        }
        return false
    }
    
    public var amount: NSNumber? {
        return self.dict["amount"] as? NSNumber
    }
    
    public var owner: String? {
        return self.dict["owner"] as? String
    }
    
    public var active: Bool {
        if let isActive = self.dict["active"] as? Bool {
            return isActive
        }
        
        return true
    }
    
    public var shareLink: String? {
        get {
            return self.dict["shareLink"] as? String
        }
    }
}

// Utils
public extension Event {
    public func dateString(_ date: Date) -> String {
        //return "\((date as NSDate).day()) \(months[(date as NSDate).month() - 1]) \((date as NSDate).year())"
        return date.dateStringForPicker()
    }
    
    public func timeString(_ date: Date) -> String {
        /*
         formatter.dateStyle = .none
         formatter.timeStyle = .short
         let time = formatter.string(from: date)
         return "\(time)"
         */
        return date.timeStringForPicker()
    }
    
    public var isFull: Bool {
        return self.maxPlayers == self.numPlayers
    }
    
    public var isPast: Bool {
        if let endTime = self.endTime {
            return (ComparisonResult.orderedAscending == endTime.compare(Date())) //event time happened before current time
        }
        else {
            return false // false means TBD
        }
    }
    
    public var locationString: String? {
        if let city = self.city, let state = self.state {
            return "\(city), \(state)"
        }
        else if let city = self.city {
            return city
        }
        else if let lat = lat, let lon = lon {
            return "\(lat), \(lon)"
        }
        return nil
    }
}

// requires Services
extension Event {
    public var numPlayers: Int {
        let users = EventService.shared.users(for: self)
        return users.count
    }
    
    public func containsPlayer(_ player: Player) -> Bool {
        let users = EventService.shared.users(for: self)
        return users.contains(player.id)
    }

    public var userIsOrganizer: Bool {
        guard let owner = owner else { return false }
        guard let user = AuthService.currentUser else { return false }
        
        return user.uid == owner
    }
}

extension Event {
    //***************** hack: for test purposes only
    class func randomEvent() -> Event {
        let key = FirebaseAPIService.uniqueId()
        let hours: Int = Int(arc4random_uniform(72))
        let dict: [String: Any] = ["type": Event.randomType() as AnyObject, "place": Event.randomPlace() as AnyObject, "startTime": (Date().timeIntervalSince1970 + Double(hours * 3600)) as AnyObject, "info": "Randomly generated event" as AnyObject]
        let event = Event(key: key, dict: dict)
        return event
    }
    
    class func randomType() -> String {
        let types: [EventType] = [.event3v3]
        let random = Int(arc4random_uniform(UInt32(types.count)))
        return types[random].rawValue
    }
    
    class func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
