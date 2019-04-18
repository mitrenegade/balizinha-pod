//
// EventService.swift
// Balizinha
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// EventService usage:
// var service = EventService.shared
// service.getEvents()

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import RenderCloud

fileprivate var singleton: EventService?

public class EventService: NSObject {
    fileprivate var _usersForEvents: [String: AnyObject] = [:]
    fileprivate var _events: [String:Balizinha.Event] = [:]
    private var _userEvents: Set<String>?
    // behaviorRelay that changes when _userEvents changes
    private var userEvents: BehaviorRelay<[String]?> = BehaviorRelay<[String]?>(value: nil)
    // observable that emits an array of eventIds, including empty arrays, but does not emit on nil
    public var userEventsObservable: Observable<[String]> {
        return userEvents
            .distinctUntilChanged()
            .filterNil()
            .asObservable()
    }
    
    // service protocols
    fileprivate let ref: Reference
    fileprivate let apiService: CloudAPIService
    public init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        ref = reference
        self.apiService = apiService
        super.init()
    }

    // read write queues
    fileprivate let readWriteQueue = DispatchQueue(label: "eventServiceReadWriteQueue", attributes: .concurrent)
    fileprivate let eventIdQueue = DispatchQueue(label: "eventServiceIdReadWriteQueue", attributes: .concurrent)
    
    // MARK: - Singleton
    public static var shared: EventService = EventService()
    public class func resetOnLogout() {
        shared._events = [:]
        shared._usersForEvents = [:]
        shared.eventIdQueue.async(flags: .barrier) {
            shared._userEvents = nil
        }
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
    
    public var featuredEvent: Variable<Balizinha.Event?> = Variable(nil)
    public func listenForEventUsers(action: (()->())? = nil) {
        // firRef is the global firebase ref
        let queryRef = ref.child(path: "eventUsers")
        queryRef.observeValue { (snapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else { return }
            if let dict = snapshot.value as? [String: AnyObject] {
                self._usersForEvents = dict
            }
            
            // can be used to trigger a notification, such as NotificationType.EventsChanged
            action?()
        }
    }

    public func getAvailableEvents(completion: (([Balizinha.Event])->Void)?) {
        guard let user = AuthService.currentUser else { return }
        apiService.cloudFunction(functionName: "getEventsAvailableToUser", method: "POST", params: ["userId": user.uid]) { [weak self] (results, error) in
            if error != nil {
                print("Error: \(error as NSError?)")
                completion?([])
            } else if let dict = results as? [String: Any], let eventsDict = dict["results"] as? [String: Any] {
                var events: [Balizinha.Event] = []
                for (key, val) in eventsDict {
                    if let dict = val as? [String: Any] {
                        let event = Balizinha.Event(key: key, dict: dict)
                        if event.isActive || event.isCancelled {
                            events.append(event)
                        }
                        self?.cache(event)
                    }
                }
                completion?(events)
            }
        }
    }
    
    public func createEvent(_ name: String, type: Balizinha.Event.EventType, city: String, state: String, lat: Double?, lon: Double?, place: String, startTime: Date, endTime: Date, maxPlayers: UInt, info: String?, paymentRequired: Bool, amount: NSNumber? = 0, leagueId: String?, completion:@escaping (Balizinha.Event?, NSError?) -> Void) {
        
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
        apiService.cloudFunction(functionName: "createEvent", method: "POST", params: params) { (result, error) in
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
    
    public func joinEvent(_ event: Balizinha.Event, userId: String, addedByOrganizer: Bool? = nil, completion: ((Error?)->Void)? = nil) {
        var params: [String: Any] = ["userId": userId, "eventId": event.id, "join": true]
        if let admin = addedByOrganizer {
            params["addedByOrganizer"] = admin
        }
        apiService.cloudFunction(functionName: "joinOrLeaveEvent", method: "POST", params: params) { (result, error) in
            if let error = error {
                print("JoinEvent error \(error)")
            }
            completion?(error)
        }
    }
    
    public func leaveEvent(_ event: Event, userId: String, removedByOrganizer: Bool? = nil, completion: ((Error?)->Void)? = nil) {
        var params: [String: Any] = ["userId": userId, "eventId": event.id, "join": false]
        if let admin = removedByOrganizer {
            params["removedByOrganizer"] = admin
        }
        apiService.cloudFunction(functionName: "joinOrLeaveEvent", method: "POST", params: params) { (result, error) in
            if let error = error {
                print("LeaveEvent error \(error)")
            }
            completion?(error)
        }
    }
    
    public func observeEvents(for user: User) {
        // returns all current events for a user. Returns as snapshot
        // TODO: does this trigger when userEvents changes ie delete on event?
        print("Get events for user \(user.uid)")
        
        let eventQueryRef = ref.child(path: "userEvents").child(path: user.uid)
        
        // do query
        eventQueryRef.observeSingleValue { [weak self] (snapshot) in
            defer {
                var events: [String]?
                self?.eventIdQueue.sync {
                    if let _events = self?._userEvents {
                        events = Array(_events)
                    }
                }
                self?.userEvents.accept(events)
                eventQueryRef.removeAllObservers()
            }
            
            guard snapshot.exists() else {
                return
            }
            if let allObjects = snapshot.childrens?.allObjects as? [Snapshot] {
                for snapshot: Snapshot in allObjects {
                    if let eventId = snapshot.key as? String, let val = snapshot.value as? Bool {
                        self?.cacheId(eventId, shouldInsert: val)
                    }
                }
            }
        }
    }
    
    public func observeUsers(for event: Balizinha.Event, completion: @escaping (_ userIds: [String]) -> Void) {
        // TODO: return each event instead of a list of userIds
        
        // returns all current events for a user. Returns as snapshot
        // only gets events once, and removes observer afterwards
        print("Get users for event \(event.id)")
        
        let queryRef = ref.child(path: "eventUsers").child(path: event.id) // this creates a query on the endpoint lotsports.firebase.com/events/
        
        // do query
        queryRef.observeSingleValue { (snapshot) in
            guard snapshot.exists() else { return }
            // this block is called for every result returned
            var results: [String] = []
            if let allObjects = snapshot.childrens?.allObjects as? [Snapshot] {
                for snapshot: Snapshot in allObjects {
                    if let userId = snapshot.key as? String, let val = snapshot.value as? Bool, val == true {
                        results.append(userId)
                    }
                }
            }
            print("getUsersForEvent \(event.id) results count: \(results.count)")
            completion(results)
        }
    }
    
    public func usersObserver(for event: Balizinha.Event) -> Observable<[String]> {
        // RX version - this allows us to stop observing
        
        return Observable.create({ (observer) -> Disposable in
            self.observeUsers(for: event, completion: { (userIds) in
                observer.onNext(userIds)
            })
            return Disposables.create()
        })
    }
    
    public func totalAmountPaid(for event: Balizinha.Event, completion: ((Double, Int)->())?) {
        let queryRef = ref.child(path: "charges/events").child(path: event.id)
        queryRef.observeValue { (snapshot) in
            guard snapshot.exists() else {
                completion?(0, 0)
                return
            }
            var total: Double = 0
            var count: Int = 0
            if let allObjects = snapshot.childrens?.allObjects as? [Snapshot] {
                for snapshot: Snapshot in allObjects {
                    let playerId = snapshot.key // TODO: display all players who've paid
                    let payment = Payment(snapshot: snapshot)
                    guard payment.paid, let amount = payment.amount, let refunded = payment.amountRefunded else { continue }
                    let netPayment: Double = (amount.doubleValue - refunded.doubleValue) / 100.0
                    total += netPayment
                    count += 1
                    print("Charges \(event.id): payment by \(playerId) = \(netPayment)")
                }
            }
            completion?(total, count)
        }
    }
    
    public func users(for event: Balizinha.Event) -> [String] {
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
    class func amountNumber(from text: String?) -> NSNumber? {
        guard let inputText = text else { return nil }
        if let amount = Double(inputText) {
            return amount as NSNumber
        }
        else if let amount = currencyFormatter.number(from: inputText) {
            return amount
        }
        return nil
    }
    
    class func amountString(from number: NSNumber?) -> String? {
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
    func withId(id: String, completion: @escaping ((Balizinha.Event?)->Void)) {
        if let found = cached(id) {
            completion(found)
            return
        }
        
        let reference = ref.child(path: "events").child(path: id)
        reference.observeValue { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let event = Balizinha.Event(snapshot: snapshot)
            self?.cache(event)
            completion(event)
            
            reference.removeAllObservers()
        }
    }
    
    func cache(_ event: Balizinha.Event) {
        readWriteQueue.async(flags: .barrier) { [weak self] in
            self?._events[event.id] = event
        }
    }
    
    func cached(_ eventId: String) -> Balizinha.Event? {
        var event: Balizinha.Event?
        readWriteQueue.sync { [weak self] in
            event = self?._events[eventId]
        }
        return event
    }
    
    func cacheId(_ eventId: String, shouldInsert: Bool) {
        eventIdQueue.async(flags: .barrier) { [weak self] in
            if self?._userEvents == nil {
                self?._userEvents = Set<String>()
            }
            if shouldInsert {
                self?._userEvents?.insert(eventId)
            } else {
                self?._userEvents?.remove(eventId)
            }
        }
    }
}

extension EventService {
    public func actions(for event: Balizinha.Event?, eventId: String? = nil, completion: @escaping ( ([Action])->() )) {
        // returns all actions
        guard let id = event?.id ?? eventId else {
            completion([])
            return
        }
        let queryRef = ref.child(path: "actions")
        queryRef.queryOrdered(by: "eventId").queryEqual(to: id).observeSingleValue { (snapshot) in
            guard snapshot.exists() else {
                completion([])
                return
            }
            var results: [Action] = []
            if let allObjects = snapshot.childrens?.allObjects as? [Snapshot] {
                for snapshot: Snapshot in allObjects {
                    let action = Action(snapshot: snapshot)
                    results.append(action)
                }
            }
            print("Actions retrieved: \(results.count) for event \(id)")
            completion(results)
        }
    }
    
    public func eventForAction(with eventId: String) -> Balizinha.Event? {
        return cached(eventId) // used by actionService for synchronous event fetch
    }
}

// cancellation
public extension EventService {
    func cancelEvent(_ event: Balizinha.Event, isCancelled: Bool, completion: ((Error?)->Void)?) {
        let params: [String: Any] = ["eventId": event.id, "isCancelled": isCancelled]
        apiService.cloudFunction(functionName: "cancelEvent", method: "POST", params: params) { (results, error) in
            if let error = error {
                completion?(error)
            } else {
                completion?(nil)
            }
        }
    }
    
    func deleteEvent(_ event: Balizinha.Event) {
        //let userId = user.uid
        let eventId = event.id
        let eventRef = ref.child(path: "events").child(path: eventId)
        eventRef.updateChildValues(["active": false])
        
        // remove users from that event by setting userEvent to false
        observeUsers(for: event) { [weak self] (ids) in
            for userId: String in ids {
                let userEventRef = self?.ref.child(path: "userEvents").child(path: userId)
                let params: [String: Any] = [eventId: false]
                userEventRef?.updateChildValues(params)
            }
        }
    }
    
}
