//
//  AuthProvider.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/25/18.
//

import UIKit
import FirebaseAuth

public protocol UserType {
    var isAnonymous: Bool { get }
}

extension User: UserType {
    
}

public protocol AuthType {

}

extension Auth: AuthType {
    
}

public protocol AuthProvider {
    // adds a listener for user state change
    func addStateDidChangeListener(_ listener: @escaping (AuthType, UserType?)->Void) -> AuthStateDidChangeListenerHandle
}

public class FIRAuthProvider: AuthProvider {
    public static var standard = FIRAuthProvider()
    private let firAuth = Auth.auth()

    public func addStateDidChangeListener(_ listener: @escaping (AuthType, UserType?) -> Void) -> AuthStateDidChangeListenerHandle {
        return firAuth.addStateDidChangeListener { (auth, user) in
            listener(auth, user)
        }
    }
}
