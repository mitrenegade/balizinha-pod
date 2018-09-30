//
//  ChatService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FeedService: NSObject {
    static let shared = FeedService()
    
    func post(leagueId: String, message: String?, image: UIImage?, completion: ((Error?)->Void)?) {
        // convenience function to encapsulate player loading and displayName for an action that is relevant to the current player
        guard let player = PlayerService.shared.current.value else {
            // this shouldn't happen
            completion?(NSError(domain: "balizinha", code: 0, userInfo: ["message": "Player not found"]))
            return
        }
        
        let id = FirebaseAPIService.uniqueId()
        let ref = firRef.child("feedItems").child(id)
        let type: FeedItemType = .chat
        let userId = player.id
        
        var params: [String: Any] = ["type": type.rawValue, "leagueId": leagueId, "userId": userId, "message": message]
        ref.setValue(params) { (error, ref) in
            print("Chat created for user \(userId) league \(leagueId) message \(message)")
            completion?(error)
        }
    }
}
