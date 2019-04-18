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
extension DatabaseReference: Reference {
    public func child(path: String) -> Reference {
        return self.child(path)
    }
    
    public func observeValue(completion: @escaping (Snapshot) -> Void) {
        observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot as? Snapshot {
                completion(snapshot)
            }
        }
    }
}
