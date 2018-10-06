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
        guard let player = PlayerService.shared.current.value else {
            // this shouldn't happen
            completion?(NSError(domain: "balizinha", code: 0, userInfo: ["message": "Player not found"]))
            return
        }
        
        let id = FirebaseAPIService.uniqueId()
        let userId = player.id
        
        var params: [String: Any] = ["leagueId": leagueId, "userId": userId]
        if let message = message {
            params["message"] = message
        }
        if let image = image {
            params["type"] = FeedItemType.photo.rawValue
            FirebaseImageService.uploadImage(image: image, type: .feed, uid: id) { (url) in
                FirebaseAPIService().cloudFunction(functionName: "createFeedItem", params: params, completion: { (result, error) in
                    print("result \(String(describing: result)) error \(String(describing: error))")
                    completion?(error)
                })
            }
        } else {
            params["type"] = FeedItemType.chat.rawValue
            FirebaseAPIService().cloudFunction(functionName: "createFeedItem", params: params, completion: { (result, error) in
                print("result \(String(describing: result)) error \(String(describing: error))")
                completion?(error)
            })
        }
    }
    
    public func observeFeedItems(for league: League, completion: @escaping (FeedItem)->Void) {
        let queryRef = firRef.child("feedItems").queryOrdered(byChild: "leagueId").queryEqual(toValue: league.id)
        
        // query for feedItems
        queryRef.observe(.value, with: { (snapshot) in
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                for snapshot in allObjects {
                    let feedItem = FeedItem(snapshot: snapshot)
                    completion(feedItem)
                }
            }
        })
    }
}
