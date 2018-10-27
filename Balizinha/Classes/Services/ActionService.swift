//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase

fileprivate var _cache: [String:FirebaseBaseModel] = [:]
public class ActionService: NSObject {
    public class func delete(action: Action) {
        let actionId = action.id
        // instead of deleting the action, just set eventActions for this action to false
        // because eventAction observers don't recognize a delete vs a change/create
        guard let eventId = action.eventId else { return }
        let queryRef = firRef.child("eventActions").child(eventId)
        queryRef.updateChildValues([actionId: false])
    }
    
    /*
     Returns actionId for every action under eventActions
     This function allows an observer to evaluate whether to load and display that action after all other actions have been loaded
     Use actions(for:) to load all actions at the beginning of a view
     */
    public func observeActions(for event: Balizinha.Event, completion: @escaping (String)->Void) {
        let queryRef = firRef.child("eventActions").child(event.id)
        
        // query for eventActions
        queryRef.observe(.value, with: { (snapshot) in
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for actionDict in allObjects {
                    let actionId = actionDict.key
                    completion(actionId)
                }
            }
        })
    }
    
    public func actions(for event: Balizinha.Event, completion: @escaping([Action]) -> Void) {
        let queryRef = firRef.child("eventActions").child(event.id)
        var actions: [Action] = []
        queryRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {
                completion([])
                return
            }
            let dispatchGroup = DispatchGroup()
            for actionDict in allObjects {
                let actionId = actionDict.key
                if let val = actionDict.value as? Bool, val == true {
                    dispatchGroup.enter()
                    self.withId(id: actionId, completion: { (action) in
                        dispatchGroup.leave()
                        if let action = action {
                            actions.append(action)
                        }
                    })
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main) {
                actions = actions.sorted() { $0.createdAt ?? Date() < $1.createdAt ?? Date() }
                completion(actions)
            }
        }
    }
    
    public func withId(id: String, completion: @escaping ((Action?)->Void)) {
        if let found = _cache[id] as? Action {
            completion(found)
            return
        }
        
        let ref = firRef.child("actions").child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let action = Action(snapshot: snapshot)
            self?.cache(action)
            completion(action)
            
            ref.removeAllObservers()
        }
    }
    
    public func cache(_ object: FirebaseBaseModel) {
        _cache[object.id] = object
    }
}
