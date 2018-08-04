//
//  AuthService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCommunity
import RxSwift

public enum LoginState {
    case loggedOut
    case loggedIn
}

public class AuthService: NSObject {
    public static var shared: AuthService = AuthService()
    
    public class var currentUser: User? {
        return firAuth.currentUser
    }

    public class var isAnonymous: Bool {
        guard let user = AuthService.currentUser else { return true }
        return user.isAnonymous
    }

    public class func startup() {
        if UserDefaults.standard.value(forKey: "appFirstTimeOpened") == nil {
            //if app is first time opened, make sure no auth exists in keychain from previously deleted app
            UserDefaults.standard.setValue(true, forKey: "appFirstTimeOpened")
            // signOut from FIRAuth
            try! firAuth.signOut()
        }
    }

    public var loginState: Observable<LoginState> = Observable.create { (observer) -> Disposable in
        print("LoginLogout: start listening for user")
        firAuth.addStateDidChangeListener({ (auth, user) in
            print("LoginLogout: auth state changed: \(auth)")
            if let user = user, !user.isAnonymous {
                // already logged in, don't do anything
                print("FirAuth: user logged in")
                observer.onNext(.loggedIn)
            }
            else {
                print("Need to display login")
                observer.onNext(.loggedOut)
            }
        })
        return Disposables.create()
    }

    public func loginUser(email: String, password: String, completion: ((Error?)->Void)?) {
        if email.isEmpty {
            print("Invalid email")
            return
        }
        
        if password.isEmpty {
            print("Invalid password")
            return
        }
        
        firAuth.signIn(withEmail: email, password: password, completion: { [weak self] (user, error) in
            if let error: NSError = error as NSError? {
                print("Error: \(error)")
                // let observer handle things
                completion?(error)
            }
            else {
                print("LoginLogout: LoginSuccess from email, results: \(String(describing: user))")
                // let observer handle things
                completion?(nil)
            }
        })
    }
    
    public var hasFacebookProvider: Bool {
        guard let user = AuthService.currentUser else { return false }
        guard !user.providerData.isEmpty else { return false }
        for provider in user.providerData {
            if provider.providerID == "facebook.com" {
                return true
            }
        }
        return false
    }
    
    public func logout() {
        print("LoginLogout: logout called, trying firAuth.signout")
        try! firAuth.signOut()
        EventService.resetOnLogout() // force new listeners
        // TODO
//        PlayerService.resetOnLogout()
//        OrganizerService.resetOnLogout()
//        FBSDKLoginManager().logOut()
//        StripeService.resetOnLogout()
//        LeagueService.resetOnLogout()
    }
}
