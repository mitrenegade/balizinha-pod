//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore
import RenderCloud

fileprivate let formatter = DateFormatter()

public class Event: FirebaseBaseModel {
    public enum EventType: String {
        case event3v3 = "3 vs 3"
        case event4v4 = "4 vs 4"
        case event5v5 = "5 vs 5"
        case event6v6 = "6 vs 6"
        case event7v7 = "7 vs 7"
        case event11v11 = "11 vs 11"
        case group = "Group class"
        case social = "Social event"
        case other
    }
    
    public enum Status: String {
        case active
        case cancelled
        case unknown
    }
    

    public var leagueId: String? {
        get {
            return dict["leagueId"] as? String ?? dict["league"] as? String
        }
        set {
            update(key: "league", value: newValue)
            update(key: "leagueId", value: newValue)
        }
    }
    
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            update(key: "name", value: newValue)
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
            update(key: "type", value: newValue)
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
    
    public var place: String? {
        get {
            return self.dict["place"] as? String
        }
        set {
            update(key: "place", value: newValue)
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
    
    public var startTime: Date? {
        get {
            if let val = self.dict["startTime"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            update(key: "startTime", value: newValue?.timeIntervalSince1970)
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
            update(key: "endTime", value: newValue?.timeIntervalSince1970)
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
            update(key: "maxPlayers", value: newValue)
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
            update(key: "info", value: newValue)
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
    
    public var organizer: String? {
        return self.dict["organizerId"] as? String ?? self.dict["organizer"] as? String
    }

    public var shareLink: String? {
        get {
            return self.dict["shareLink"] as? String
        }
    }
    
    public var venueId: String? {
        get {
            return dict["venueId"] as? String
        }
        set {
            update(key: "venueId", value: newValue)
        }
    }
    
    public var recurrence: Date.Recurrence {
        get {
            guard let str = self.dict["recurrence"] as? String else { return .none }
            return Date.Recurrence(rawValue: str) ?? .none
        }
        set {
            update(key: "recurrence", value: newValue.rawValue)
        }
    }
    
    // date on which this event will end. This should be a generated timestamp that is inclusive, so this should always be greater than the start time of the original date
    public var recurrenceEndDate: Date? {
        get {
            if let val = dict["recurrenceEndDate"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil
        }
        set {
            update(key: "recurrenceEndDate", value: newValue?.timeIntervalSince1970)
        }
    }
    // ID of event that originally created this event
    public var recurrenceId: String? {
        get {
            return self.dict["recurrenceId"] as? String
        }
        set {
            update(key: "recurrenceId", value: newValue)
        }
    }
    
    public var videoUrl: String? {
        get {
            return self.dict["videoUrl"] as? String
        }
        set {
            update(key: "videoUrl", value: newValue)
        }
    }
}

public extension Event {
    private var status: Status {
        if let statusString = dict["status"] as? String, let status = Status(rawValue: statusString) {
            return status
        }
        return .unknown
    }

    var isActive: Bool {
        // status supercedes active because absense of ["active"] means active
        if status == .unknown {
            if let isActive = self.dict["active"] as? Bool {
                return isActive
            }
            return true
        }

        return status == .active
    }

    var isCancelled: Bool {
        if status == .unknown {
            if let isActive = self.dict["active"] as? Bool, !isActive {
                return true
            }
        }
        return status == .cancelled
    }
}

// Utils
extension Event {
    public func dateString(_ date: Date, from reference: Date? = nil) -> String {
        if let reference = reference, recurrence != .none {
            if let nextDate = date.getNextRecurrence(recurrence: self.recurrence, from: reference) {
                return nextDate.dateStringForPicker()
            }
        }
        return date.dateStringForPicker()
    }
    
    public func timeString(_ date: Date) -> String {
        return date.timeStringForPicker()
    }
    
    public var isFull: Bool {
        return self.maxPlayers == self.numPlayers()
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
    
    public class func validUrl(_ urlString: String?) -> URL? {
        guard let url = urlString else { return nil }
        return URL(string: url)
    }
    
    public var validVideoUrl: URL? {
        return Event.validUrl(videoUrl)
    }
}

// requires Services
extension Event {
    public func numPlayers(service: EventService = EventService.shared) -> Int {
        let users = service.attendance(for: self.id, attending: true)
        return users.count
    }
    
    public func playerIsAttending(_ player: Player, service: EventService = EventService.shared) -> Bool {
        let users = service.attendance(for: self.id, attending: true)
        return users.contains(player.id)
    }

    public func playerOptedOut(_ player: Player, service: EventService = EventService.shared) -> Bool {
        let users = service.attendance(for: self.id, attending: false)
        return users.contains(player.id)
    }

    public func playerHasResponded(_ player: Player, service: EventService = EventService.shared) -> Bool {
        let users = service.attendance(for: self.id)
        return users.contains(player.id)
    }

    public func userIsOrganizer(_ userId: String? = PlayerService.shared.current.value?.id) -> Bool {
        guard let organizerId = organizer else { return false }
        guard let userId = userId else { return false }
        return userId == organizerId
    }
}
