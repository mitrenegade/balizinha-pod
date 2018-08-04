//
//  FirebaseBaseModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity

public let firRef = Database.database().reference()
public let firAuth = Auth.auth()

public class FirebaseBaseModel: NSObject {
    // Firebase objects have structure:
    // id: {
    //  key1: val1
    //  key2: val2
    //  ..
    // }
    
    public var firebaseKey: String! // store id
    public var firebaseRef: DatabaseReference? // url like lotsportz.firebase.com/model/id
    public var dict: [String: Any]! // {key1: val1, key2: val2 ...}
    
    public init(snapshot: DataSnapshot?) {
        if let snapshot = snapshot, snapshot.exists() {
            self.firebaseKey = snapshot.key
            self.firebaseRef = snapshot.ref
            self.dict = snapshot.value as? [String: AnyObject]
            
            // a new user doesn't have a dictionary
            if self.dict == nil {
                self.dict = [:]
            }
        }
    }
    
    public init(key: String, dict: [String: Any]?) {
        self.firebaseKey = key
        self.firebaseRef = nil // no ref from a dict
        self.dict = dict ?? [:]
    }
    
    override convenience init() {
        self.init(snapshot: nil)
    }
    
    // returns dict, or the value/contents of this object
    func toAnyObject() -> AnyObject {
        return self.dict as AnyObject
    }
    
    // returns unique id for this firebase object
    public var id: String {
        return self.firebaseKey
    }
    
    public var createdAt: Date? {
        if let val = self.dict["createdAt"] as? TimeInterval {
            let time1970: TimeInterval = 1517606802
            if val > time1970 * 10.0 {
                return Date(timeIntervalSince1970: (val / 1000.0))
            } else {
                return Date(timeIntervalSince1970: val)
            }
        }
        return nil
    }
}
