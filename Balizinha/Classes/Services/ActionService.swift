//
//  ActionService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseCore
import RenderCloud

public class ActionService: BaseService {
    public static let shared: ActionService = ActionService()

    override var refName: String {
        return "actions"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Action(snapshot: snapshot)
    }

    public func delete(action: Action, completion:((Error?)->Void)? = nil) {
        let actionId = action.id
        
        /*
        // instead of deleting the action, just set eventActions for this action to false
        // because eventAction observers don't recognize a delete vs a change/create
        guard let eventId = action.eventId else { return }
        let queryRef = firRef.child("eventActions").child(eventId)
        queryRef.updateChildValues([actionId: false])
        
        action.visible = false
        */
        
        let params = ["actionId": actionId]
        apiService.cloudFunction(functionName: "deleteActionAndEventAction", method: "POST", params: params) { (result, error) in
            print("DeleteActionAndEventAction: result \(result) error \(error)")
            DispatchQueue.main.async {
                completion?(error)
            }
        }
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
                        if let action = action as? Action {
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
}
