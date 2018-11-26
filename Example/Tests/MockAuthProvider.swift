//
//  MockAuthProvider.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import FirebaseAuth
import FirebaseCore

class MockAuthProvider: NSObject, AuthProvider {
    func addStateDidChangeListener(_ listener: @escaping (AuthType, UserType?) -> Void) -> AuthStateDidChangeListenerHandle {
        listener(mockAuth, mockUser)
        
        return NSObject()
    }
    
    var mockAuth: AuthType! = MockAuthType()
    var mockUser: UserType?
}

class MockAuthType: AuthType {
    
}

class MockUserType: UserType {
    var isAnonymous: Bool {
        return false
    }
}
