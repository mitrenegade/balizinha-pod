
//
//  PlayerService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCommunity
import RxSwift
import RxOptional

public class PlayerService: NSObject {
    // MARK: - Singleton
    public static var shared: PlayerService = PlayerService()
    
    fileprivate static var cachedNames: [String: String] = [:]
    
    fileprivate var disposeBag: DisposeBag
    
    public let current: Variable<Player?> = Variable(nil)
    fileprivate let playersRef: DatabaseReference
    fileprivate var currentPlayerRef: DatabaseReference?
    
    // for a new user, set this flag on the first time they log in
    public var needsToCreateProfile: Bool = false
    
    public override init() {
        disposeBag = DisposeBag()
        playersRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/players/
        playersRef.keepSynced(true)
        
        super.init()
        
        startAuthListener()
    }
    
    public func startAuthListener() {
        AuthService.shared.loginState.asObservable().distinctUntilChanged().subscribe(onNext: {state in
            if state == .loggedIn, let user = AuthService.currentUser {
                print("PlayerService: log in state triggering player request with logged in user \(user.uid)")
                self.refreshCurrentPlayer()
            }
        }).disposed(by: disposeBag)
    }
    
    public func refreshCurrentPlayer() {
        guard let user = AuthService.currentUser else { return }
        currentPlayerRef?.removeAllObservers()
        currentPlayerRef = self.playersRef.child(user.uid)
        currentPlayerRef?.observe(.value, with: { [weak self] (snapshot) in
            guard snapshot.exists() else { return }
            
            let player = Player(snapshot: snapshot)
            print("PlayerService: loaded player \(player.id)")
            self?.current.value = player
            
            self?.currentPlayerRef?.removeAllObservers()
            self?.currentPlayerRef = nil
        })
    }
    
    public class func resetOnLogout() {
        print("PlayerService resetOnLogout")
        shared.disposeBag = DisposeBag()
        shared.current.value = nil
        shared.startAuthListener()
        shared.currentPlayerRef?.removeAllObservers()
    }
    
    
    public func createPlayer(name: String?, email: String?, city: String?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {
        
        guard let user = AuthService.currentUser, !AuthService.isAnonymous else { return }
        let existingUserId = user.uid
        let newPlayerRef: DatabaseReference = playersRef.child(existingUserId)
        
        print("PlayerService createPlayer")
        
        var params: [String: Any] = [:]
        if let name = name {
            params["name"] = name
        }
        if let email = email {
            params["email"] = email
        }
        if let city = city {
            params["city"] = city
        }
        if let info = info {
            params["info"] = info
        }
        if let photoUrl = photoUrl {
            params["photoUrl"] = photoUrl
        }
        
        newPlayerRef.setValue(params) { (error, ref) in
            if let error = error as NSError? {
                print(error)
                completion(nil, error)
            } else {
                PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { player in
                    completion(player, nil)
                })
            }
        }
    }
    
    public func withId(id: String, completion: @escaping ((Player?)->Void)) {
        let ref = playersRef.child(id)
        ref.observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            ref.removeAllObservers()
            let player = Player(snapshot: snapshot)
            PlayerService.cachedNames[id] = player.name
            completion(player)
        }
    }
}

// Profile and Facebook Photo
extension PlayerService {
    func storeUserInfo() {
        guard let user = AuthService.currentUser else { return }
        
        print("signIn results: \(user.uid) profile \(String(describing: user.photoURL)) \(String(describing: user.displayName))")
        createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { [weak self] (player, error) in
            print("PlayerService storeUserInfo complete")
        })
    }
}