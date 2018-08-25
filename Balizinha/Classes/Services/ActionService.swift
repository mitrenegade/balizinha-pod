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
        guard let eventId = action.event else { return }
        let queryRef = firRef.child("eventActions").child(eventId)
        queryRef.updateChildValues([actionId: false])
    }
    
    public func observeActions(forEvent event: Balizinha.Event, completion: @escaping (Action)->Void) {
        // sort by time
        let queryRef = firRef.child("eventActions").child(event.id)
        
        // query for eventActions
        queryRef.observe(.value, with: { (snapshot) in
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for actionDict in allObjects {
                    let actionId = actionDict.key
                    if let val = actionDict.value as? Bool, val == true {
                        // query for the action. val should not be false - deleted action should be deleted from eventActions
                        // query for the action
                        let actionQueryRef = firRef.child("actions").child(actionId)
                        actionQueryRef.observeSingleEvent(of: .value, with: { (actionSnapshot) in
                            if actionSnapshot.exists() {
                                let action = Action(snapshot: actionSnapshot)
                                self.cache(action)
                                completion(action)
                            }
                        })
                    }
                }
            }
        })
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