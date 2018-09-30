//
//  ChatService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase

public class FeedService: NSObject {
    public static let shared = FeedService()
    
    public func post(leagueId: String, message: String?, image: UIImage?, completion: ((Error?)->Void)?) {
        // convenience function to encapsulate player loading and displayName for an action that is relevant to the current player
        guard let player = PlayerService.shared.current.value else {
            // this shouldn't happen
            completion?(NSError(domain: "balizinha", code: 0, userInfo: ["message": "Player not found"]))
            return
        }
        
        let id = FirebaseAPIService.uniqueId()
        let feedRef = firRef.child("feedItems").child(id)
        let userId = player.id
        
        var params: [String: Any] = ["leagueId": leagueId, "userId": userId]
        if let message = message {
            params["message"] = message
        }
        if let image = image {
            params["type"] = FeedItemType.photo.rawValue
            FirebaseImageService.uploadImage(image: image, type: .feed, uid: id) { (url) in
                params["image"] = true
                feedRef.setValue(params) { (error, ref) in
                    print("Chat created for user \(userId) league \(leagueId) message \(String(describing: message))")
                    completion?(error)
                }
            }
        } else {
            params["type"] = FeedItemType.chat.rawValue
            feedRef.setValue(params) { (error, ref) in
                print("Chat created for user \(userId) league \(leagueId) message \(String(describing: message))")
                completion?(error)
            }
        }
    }
}
