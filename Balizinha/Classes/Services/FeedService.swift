//
//  ChatService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase
import RenderCloud

public class FeedService: NSObject {
    public static let shared = FeedService()
    
    public func post(leagueId: String, message: String?, image: UIImage?, completion: ((Error?)->Void)?) {
        guard let player = PlayerService.shared.current.value else {
            // this shouldn't happen
            completion?(NSError(domain: "balizinha", code: 0, userInfo: ["message": "Player not found"]))
            return
        }
        
        let id = RenderAPIService().uniqueId()
        let userId = player.id
        
        var params: [String: Any] = ["leagueId": leagueId, "userId": userId, "id": id]
        if let message = message, !message.isEmpty {
            params["message"] = message
        }
        if let image = image {
            params["type"] = FeedItemType.photo.rawValue
            let dispatchGroup = DispatchGroup()
            var createResult: Any?
            var createError: Error?
            dispatchGroup.enter()
            FirebaseImageService.uploadImage(image: image, type: .feed, uid: id) { (url) in
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            RenderAPIService().cloudFunction(functionName: "createFeedItem", params: params, completion: { (result, err) in
                createResult = result
                createError = err
                dispatchGroup.leave()
            })
            
            dispatchGroup.notify(queue: DispatchQueue.main) {
                print("result \(String(describing: createResult)) error \(String(describing: createError))")
                completion?(createError)
            }
            
        } else {
            params["type"] = FeedItemType.chat.rawValue
            RenderAPIService().cloudFunction(functionName: "createFeedItem", params: params, completion: { (result, error) in
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
                    if feedItem.visible {
                        completion(feedItem)
                    }
                }
            }
        })
    }
    
    public func loadFeedItems(for league: League, lastId: String? = nil, pageSize: UInt = 10, completion: @escaping (([FeedItem]) -> Void)) {
        var queryRef = firRef
            .child("leagueFeedItems")
            .child(league.id)
            .queryLimited(toFirst: pageSize)
        if let lastId = lastId {
            queryRef = queryRef.queryStarting(atValue: lastId, childKey: "id")
        }
        queryRef.observeSingleValue { (snapshot) in
            var feedItems = [FeedItem]()
            for snapshot in snapshot.allChildren ?? [] {
                let feedItem = FeedItem(snapshot: snapshot)
                if feedItem.visible {
                    feedItems.append(feedItem)
                }
            }
            completion(feedItems)
        }
    }

    public func delete(feedItemId: String) {
        let queryRef = firRef.child("feedItems").child(feedItemId)
        queryRef.updateChildValues(["visible": false])
    }
    
    public class func delete(feedItem: FeedItem) {
        feedItem.visible = false
    }
}
