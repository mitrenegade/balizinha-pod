//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

public enum EventType: String {
    case event3v3 = "3 vs 3"
    case event5v5 = "5 vs 5"
    case event7v7 = "7 vs 7"
    case event11v11 = "11 vs 11"
    case other
}

fileprivate let formatter = DateFormatter()

public class Event: FirebaseBaseModel {
    public var service = EventService.shared
    
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
            for type: EventType in [.event3v3, .event5v5, .event7v7, .event11v11] {
                if type.rawValue == self.dict["type"] as? String {
                    return type
                }
            }
            return .other
        }
        set {
            self.dict["type"] = newValue.rawValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    // event's photoId may not be its UID. before event is saved
    public var photoId: String? {
        get {
            return self.dict["photoId"] as? String
        }
        set {
            self.dict["photoId"] = newValue
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
//        guard SettingsService.paymentRequired() else { return false }
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
    
    public var numPlayers: Int {
        let users = self.users
        return users.count
    }
    
    public var users: [String] {
        guard let usersForEvents = self.service.usersForEvents else { return [] }
        if let results = usersForEvents[self.id] as? [String: AnyObject] {
            let filtered = results.filter({ (arg) -> Bool in
                
                let (key, val) = arg
                return val as! Bool
            })
            let userIds = filtered.map({ (arg) -> String in
                
                let (key, val) = arg
                return key
            })
            return userIds
        }
        return []
    }
    
    public func containsPlayer(_ player: Player) -> Bool {
        return self.users.contains(player.id)
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
    
    public var userIsOrganizer: Bool {
        guard let owner = self.owner else { return false }
        guard let user = AuthService.currentUser else { return false }
        
        return user.uid == owner
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

extension Event {
    //***************** hack: for test purposes only
    class func randomEvent() -> Event {
        let event = Event()
        let hours: Int = Int(arc4random_uniform(72))
        event.dict = ["type": event.randomType() as AnyObject, "place": event.randomPlace() as AnyObject, "startTime": (Date().timeIntervalSince1970 + Double(hours * 3600)) as AnyObject, "info": "Randomly generated event" as AnyObject]
        event.firebaseKey = FirebaseAPIService.uniqueId()
        return event
    }
    
    func randomType() -> String {
        let types: [EventType] = [.event3v3]
        let random = Int(arc4random_uniform(UInt32(types.count)))
        return types[random].rawValue
    }
    
    func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}