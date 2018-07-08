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
import FirebaseCommunity

fileprivate var _events: [String: Event] = [:]
public class EventService: NSObject {
    static var shared: EventService = EventService()

    func totalAmountPaid(for event: Event, completion: ((Double, Int)->())?) {
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
    
    func actions(for event: Event?, eventId: String? = nil, completion: @escaping ( ([Action])->() )) {
        // returns all actions
        guard let id = event?.id ?? eventId else {
            completion([])
            return
        }
        let queryRef = firRef.child("actions")
        queryRef.queryOrdered(byChild: "event").queryEqual(toValue: id).observe(.value, with: { (snapshot) in
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
}

// MARK: - Payment helpers
extension EventService {
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

    func eventForAction(with eventId: String) -> Balizinha.Event? {
        return _events[eventId] // used by actionService for quick stuff
    }
    
    func withId(id: String, completion: @escaping ((Balizinha.Event?)->Void)) {
        if let found = _events[id] {
            completion(found)
            return
        }
        
        let eventRef = firRef.child("events")
        eventRef.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let event = Event(snapshot: snapshot)
            _events[id] = event
            completion(event)
        })
    }
}
