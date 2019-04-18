//
//  FirebaseExtensions.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/18/19.
//

import Foundation
import RenderCloud
import FirebaseDatabase

// conform Firebase's DatabaseReference to RenderCloud Reference
extension DataSnapshot: Snapshot {
    public var allChildren: [Snapshot]? {
        return children.allObjects as? [Snapshot]
    }
    
    public var reference: Reference? {
        return ref
    }
}

extension DatabaseReference: Reference {
    public func observeSingleValue(completion: @escaping (Snapshot) -> Void) {
        observeSingleEvent(of: .value, with: completion)
    }
    
    public func queryOrdered(by child: String) -> Query {
        return queryOrdered(byChild: child)
    }
    
    public func child(path: String) -> Reference {
        return child(path)
    }
    
    public func observeValue(completion: @escaping (Snapshot) -> Void) {
        observe(.value, with: completion)
    }
}

extension DatabaseQuery: Query {
    public func queryEqual(to value: Any) -> Reference {
        return queryEqual(toValue: value) as! Reference
    }
}
