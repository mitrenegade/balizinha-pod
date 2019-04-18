//
//  FirebaseExtensions.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/18/19.
//

import Foundation
import RenderCloud
import FirebaseDatabase

// BOBBY TODO: this should go into RenderCloud?
// conform Firebase's DatabaseReference to RenderCloud Reference
extension DataSnapshot: Snapshot {
    public var childrens: NSEnumerator? {
        return self.children
    }
    
    public var reference: Reference? {
        return ref
    }
}

extension DatabaseReference: Reference {
    public func observeSingleValue(completion: @escaping (Snapshot) -> Void) {
        observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot as? Snapshot {
                completion(snapshot)
            }
        }
    }
    
    public func queryOrdered(by child: String) -> Query {
        return queryOrdered(byChild: child)
    }
    
    public func child(path: String) -> Reference {
        return self.child(path)
    }
    
    public func observeValue(completion: @escaping (Snapshot) -> Void) {
        observe(.value) { (snapshot) in
            
        }
    }
}

extension DatabaseQuery: Query {
    public func queryEqual(to value: Any) -> Reference {
        return queryEqual(toValue: value) as! Reference
    }
}
