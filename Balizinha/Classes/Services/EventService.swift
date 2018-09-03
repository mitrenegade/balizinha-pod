//
//  EventService.swift
// Balizinha
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// EventService usage:
// var service = EventService.shared
// service.getEvents()

import UIKit
import FirebaseCore
import RxSwift
import FirebaseAuth
import FirebaseDatabase

fileprivate var singleton: EventService?

public class EventService: NSObject {
    fileprivate var _usersForEvents: [String: AnyObject] = [:]
    fileprivate var _events: [String:Event] = [:]
    
    // MARK: - Singleton
    public static var shared: EventService {
        if singleton == nil {
            singleton = EventService()
            singleton?._events = [:]
            singleton?._usersForEvents = [:]
        }
        
        return singleton!
    }
    
    public class func resetOnLogout() {
        singleton = nil
    }
    
    public var featuredEventId: String? {
        didSet {
            if let eventId = featuredEventId {
                withId(id: eventId, completion: {[weak self] (event) in
                    self?.featuredEvent.value = event
                })
            } else {
                featuredEvent.value = nil
            }
        }
    }
    
    public var featuredEvent: Variable<Event?> = Variable(nil)
    public func listenForEventUsers(action: (()->())? = nil) {
        // firRef is the global firebase ref
        let queryRef = firRef.child("eventUsers")
        queryRef.observe(.value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else { return }
            if let dict = snapshot.value as? [String: AnyObject] {
                self._usersForEvents = dict
            }
            
            // can be used to trigger a notification, such as NotificationType.EventsChanged
            action?()
        }
    }
    
    // MARK: - Single call listeners
    
    public func getEvents(type: String?, completion: @escaping (_ results: [Event]) -> Void) {
        // returns all current events of a certain type. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events")
        
        let eventQueryRef = firRef.child("events")//childByAppendingPath("events") // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // sort by time
        eventQueryRef.queryOrdered(byChild: "startTime")
        
        // filter for type - this does not work
        /*
         if let _ = type {
         // should be queryOrdered(byChild: "type").equalTo(type)
         eventQueryRef.queryEqual(toValue: type!, childKey: "type")
         }
         */
        
        eventQueryRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else {
                completion([])
                return
            }
            var results: [Event] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for eventDict: DataSnapshot in allObjects {
                    guard eventDict.exists() else { continue }
                    let event = Event(snapshot: eventDict)
                    if event.active {
                        results.append(event)
                    }
                }
            }
            print("getEvents results count: \(results.count)")
            for event in results {
                self.cache(event)
            }
            completion(results)
        }
    }
    
    public func createEvent(_ name: String, type: EventType, city: String, state: String, lat: Double?, lon: Double?, place: String, startTime: Date, endTime: Date, maxPlayers: UInt, info: String?, paymentRequired: Bool, amount: NSNumber? = 0, leagueId: String?, completion:@escaping (Event?, NSError?) -> Void) {
        
        print ("Create events")
        
        guard let user = AuthService.currentUser else { return }
        
        var params: [String: Any] = ["name": name, "type": type.rawValue, "city": city, "state": state, "place": place, "startTime": startTime.timeIntervalSince1970, "endTime": endTime.timeIntervalSince1970, "maxPlayers": maxPlayers, "userId": user.uid, "paymentRequired": paymentRequired]
        if let lat = lat, let lon = lon {
            params["lat"] = lat
            params["lon"] = lon
        }
        if paymentRequired {
            params["paymentRequired"] = true
            params["amount"] = amount
        }
        if let leagueId = leagueId {
            params["league"] = leagueId
        }
        if let info = info {
            params["info"] = info
        }
        FirebaseAPIService().cloudFunction(functionName: "createEvent", params: params) { (result, error) in
            if let error = error as NSError? {
                print("CreateEvent v1.4 failed with error \(error)")
                completion(nil, error)
            } else {
                print("CreateEvent v1.4 success with result \(String(describing: result))")
                if let dict = result as? [String: Any], let eventId = dict["eventId"] as? String {
                    self.withId(id: eventId, completion: { (event) in
                        // TODO: the event returned is always nil?
                        guard let event = event else {
                            return
                        }
                        completion(event, nil)
                    })
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    public func deleteEvent(_ event: Event) {
        //let userId = user.uid
        let eventId = event.id
        let eventRef = firRef.child("events").child(eventId)
        eventRef.updateChildValues(["active": false])
        
        // remove users from that event by setting userEvent to false
        observeUsers(for: event) { (ids) in
            for userId: String in ids {
                let userEventRef = firRef.child("userEvents").child(userId)
                let params: [String: Any] = [eventId: false]
                userEventRef.updateChildValues(params, withCompletionBlock: { (error, ref) in
                })
            }
        }
        
        
    }
    public func joinEvent(_ event: Event, userId: String, addedByOrganizer: Bool? = nil, completion: ((Error?)->Void)? = nil) {
        var params: [String: Any] = ["userId": userId, "eventId": event.id, "join": true]
        if let admin = addedByOrganizer {
            params["addedByOrganizer"] = admin
        }
        FirebaseAPIService().cloudFunction(functionName: "joinOrLeaveEvent", params: params) { (result, error) in
            if let error = error {
                print("JoinEvent error \(error)")
            }
            completion?(error)
        }
    }
    
    public func leaveEvent(_ event: Event, userId: String, removedByOrganizer: Bool? = nil, completion: ((Error?)->Void)? = nil) {
        var params: [String: Any] = ["userId": userId, "eventId": event.id, "join": false]
        if let admin = removedByOrganizer {
            params["removedByOrganizer"] = removedByOrganizer
        }
        FirebaseAPIService().cloudFunction(functionName: "joinOrLeaveEvent", params: params) { (result, error) in
            if let error = error {
                print("JoinEvent error \(error)")
            }
            completion?(error)
        }
    }
    
    public func getEvents(for user: User, completion: @escaping (_ eventIds: [String]) -> Void) {
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get events for user \(user.uid)")
        
        let eventQueryRef = firRef.child("userEvents").child(user.uid)
        
        // do query
        eventQueryRef.observe(.value) { (snapshot) in
            guard snapshot.exists() else {
                completion([])
                return
            }
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let eventId = snapshot.key
                    if let val = snapshot.value as? Bool {
                        if val == true {
                            results.append(eventId)
                        }
                    }
                }
            }
            print("getEventsForUser \(user.uid) results count: \(results.count)")
            completion(results)
            eventQueryRef.removeAllObservers()
        }
    }
    
    public func observeUsers(for event: Event, completion: @escaping (_ userIds: [String]) -> Void) {
        // TODO: return each event instead of a list of userIds
        
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get users for event \(event.id)")
        
        let queryRef = firRef.child("eventUsers").child(event.id) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        queryRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard snapshot.exists() else { return }
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let userId = snapshot.key
                    if let val = snapshot.value as? Bool, val == true {
                        results.append(userId)
                    }
                }
            }
            print("getUsersForEvent \(event.id) results count: \(results.count)")
            completion(results)
        }
    }
    
    public func usersObserver(for event: Event) -> Observable<[String]> {
        // RX version - this allows us to stop observing
        
        return Observable.create({ (observer) -> Disposable in
            self.observeUsers(for: event, completion: { (userIds) in
                observer.onNext(userIds)
            })
            return Disposables.create()
        })
    }
    
    public func totalAmountPaid(for event: Event, completion: ((Double, Int)->())?) {
        let queryRef = firRef.child("charges/events").child(event.id)
        queryRef.observe(.value) { (snapshot: DataSnapshot) in
            guard snapshot.exists() else {
                completion?(0, 0)
                return
            }
            var total: Double = 0
            var count: Int = 0
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let playerId = snapshot.key // TODO: display all players who've paid
                    let payment = Payment(snapshot: snapshot)
                    guard payment.paid, let amount = payment.amount, let refunded = payment.refunded else { continue }
                    let netPayment: Double = (amount.doubleValue - refunded.doubleValue) / 100.0
                    total += netPayment
                    count += 1
                    print("Charges \(event.id): payment by \(playerId) = \(netPayment)")
                }
            }
            completion?(total, count)
        }
    }
    
    public func users(for event: Event) -> [String] {
        if let results = _usersForEvents[event.id] as? [String: AnyObject] {
            let filtered = results.filter({ (arg) -> Bool in
                let (_, val) = arg
                return val as! Bool
            })
            let userIds = filtered.map({ (arg) -> String in
                let (key, _) = arg
                return key
            })
            return userIds
        }
        return []
    }
}

// MARK: - Payment helpers
public extension EventService {
    public class func amountNumber(from text: String?) -> NSNumber? {
        guard let inputText = text else { return nil }
        if let amount = Double(inputText) {
            return amount as NSNumber
        }
        else if let amount = currencyFormatter.number(from: inputText) {
            return amount
        }
        return nil
    }
    
    public class func amountString(from number: NSNumber?) -> String? {
        guard let number = number else { return nil }
        return currencyFormatter.string(from: number)
    }
    
    fileprivate static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.currencyDecimalSeparator = "."
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
}

public extension EventService {
    public func withId(id: String, completion: @escaping ((Event?)->Void)) {
        if let found = _events[id] {
            completion(found)
            return
        }
        
        let ref = firRef.child("events").child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let event = Event(snapshot: snapshot)
            self?.cache(event)
            completion(event)
            
            ref.removeAllObservers()
        }
    }
    
    public func cache(_ event: Event) {
        _events[event.id] = event
    }
}

extension EventService {
    public func actions(for event: Event?, eventId: String? = nil, completion: @escaping ( ([Action])->() )) {
        // returns all actions
        guard let id = event?.id ?? eventId else {
            completion([])
            return
        }
        let queryRef = firRef.child("actions")
        queryRef.queryOrdered(byChild: "event").queryEqual(toValue: id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion([])
                return
            }
            var results: [Action] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot: DataSnapshot in allObjects {
                    let action = Action(snapshot: snapshot)
                    results.append(action)
                }
            }
            print("Actions retrieved: \(results.count) for event \(id)")
            completion(results)
        }, withCancel: nil)
    }
    
    public func eventForAction(with eventId: String) -> Balizinha.Event? {
        return _events[eventId] // used by actionService for quick stuff
    }
}
