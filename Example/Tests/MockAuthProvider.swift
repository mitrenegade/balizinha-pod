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
    var listener: ((AuthType, UserType?) -> Void)?
    func addStateDidChangeListener(_ listener: @escaping (AuthType, UserType?) -> Void) -> AuthStateDidChangeListenerHandle {
        self.listener = listener
        
        return NSObject()
    }
    
    var mockAuth: AuthType! = MockAuthType() {
        didSet {
            listener?(mockAuth, mockUser)
        }
    }
    var mockUser: UserType? {
        didSet {
            listener?(mockAuth, mockUser)
        }
    }
}

class MockAuthType: AuthType {
    
}

class MockUserType: UserType {
    var mockIsAnonymous: Bool = false
    var isAnonymous: Bool {
        return mockIsAnonymous
    }
}
