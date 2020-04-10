
//
//  PlayerService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore
import RxSwift
import RxCocoa
import RxOptional
import FirebaseDatabase
import RenderCloud
import PannaPay

public class PlayerService: BaseService {
    // MARK: - Singleton
    public static var shared: PlayerService = PlayerService()
    
    fileprivate var disposeBag: DisposeBag
    
    public let current: BehaviorRelay<Player?> = BehaviorRelay(value: nil)
    fileprivate var playersRef: Reference?
    fileprivate var currentPlayerRef: Reference?
    
    // for a new user, set this flag on the first time they log in
    public var needsToCreateProfile: Bool = false
    
    public override init(apiService: (CloudAPIService & CloudDatabaseService & ServiceAPIProvider)? = nil) {

        disposeBag = DisposeBag()
        super.init(apiService: apiService)

        playersRef = self.apiService.playersRef// this references the endpoint lotsports.firebase.com/players/
        (playersRef as? DatabaseReference)?.keepSynced(true)

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
        currentPlayerRef = playersRef?.child(path: user.uid)
        currentPlayerRef?.observeSingleValue { [weak self] (snapshot) in
            guard snapshot.exists() else { return }
            
            let player = Player(snapshot: snapshot)
            print("PlayerService: loaded player \(player.id)")
            self?.current.accept(player)
            
            self?.currentPlayerRef?.removeAllObservers()
            self?.currentPlayerRef = nil
        }
    }
    
    public class func resetOnLogout() {
        shared.disposeBag = DisposeBag()
        shared.current.accept(nil)
        shared.startAuthListener()
        shared.currentPlayerRef?.removeAllObservers()
    }
    
    
    public func createPlayer(name: String?, email: String?, city: City?, info: String?, photoUrl: String?, completion:@escaping (Player?, NSError?) -> Void) {
        
        guard let user = AuthService.currentUser, !AuthService.isAnonymous else { return }
        let existingUserId = user.uid
        guard let newPlayerRef: DatabaseReference = playersRef?.child(path: existingUserId) as? DatabaseReference else { return }
        
        print("PlayerService createPlayer")
        
        var params: [String: Any] = [:]
        if let name = name {
            params["name"] = name
        }
        if let email = email {
            params["email"] = email
        }
        if let cityId = city?.id {
            params["cityId"] = cityId
        }
        if let info = info {
            params["info"] = info
        }
        if let photoUrl = photoUrl {
            params["photoUrl"] = photoUrl
        }
        
        newPlayerRef.setValue(params) { [weak self] (error, ref) in
            guard let self = self else { return }
            if let error = error as NSError? {
                print(error)
                completion(nil, error)
            } else {
                self.current.asObservable().filterNil().take(1).subscribe(onNext: { player in
                    completion(player, nil)
                }).disposed(by: self.disposeBag)
            }
        }
    }
    
    override var refName: String {
        return "players"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Player(snapshot: snapshot)
    }

    public func updateCityAndNotify(city: City?) {
        if let player = current.value {
            player.cityId = city?.firebaseKey

            current.accept(player) // causes observers to be notified
        }
    }
}

// Profile and Facebook Photo
extension PlayerService {
    open func storeUserInfo() {
        guard let user = AuthService.currentUser else { return }
        
        createPlayer(name: user.displayName, email: user.email, city: nil, info: nil, photoUrl: user.photoURL?.absoluteString, completion: { (player, error) in
        })
    }
}
