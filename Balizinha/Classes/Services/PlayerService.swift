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

var _players: [String: Player] = [:]
class PlayerService: NSObject {
    // MARK: - Singleton
    static var shared: PlayerService = PlayerService()
    
    fileprivate var disposeBag: DisposeBag
    fileprivate let playersRef: DatabaseReference

    override init() {
        disposeBag = DisposeBag()
        playersRef = firRef.child("players") // this references the endpoint lotsports.firebase.com/players/
        playersRef.keepSynced(true)
        
        super.init()
    }

    func withId(id: String, completion: @escaping ((Player?)->Void)) {
        if let found = _players[id] {
            completion(found)
            return
        }

        playersRef.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            let player = Player(snapshot: snapshot)
            _players[id] = player
            completion(player)
        })
    }
    
    var currentCachedPlayers: [Player] {
        return Array(_players.values)
    }
}
