//
//  LeagueService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/10/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseCommunity

fileprivate var _leagues: [String: League] = [:]
class LeagueService: NSObject {
    static let shared: LeagueService = LeagueService()
    
    func create(name: String, city: String, info: String, completion: @escaping ((_ result: Any?, _ error: Error?)->Void)) {
        guard let user = AuthService.currentUser else { return }
        let params = ["name": name, "city": city, "info": info, "userId": user.uid]
        FirebaseAPIService().cloudFunction(functionName: "createLeague", method: "POST", params: params, completion: { (result, error) in
            guard error == nil else {
                print("League creation error \(error)")
                completion(nil, error)
                return
            }
            print("League creation result \(result)")
            completion(result, nil)
        })
    }
    
    func join(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        FirebaseAPIService().cloudFunction(functionName: "joinLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id]) { (result, error) in
            guard error == nil else {
                print("League join error \(error)")
                completion(nil, error)
                return
            }
            print("League join result \(result)")
            completion(result, nil)
        }
    }

    func getLeagues(completion: @escaping (_ results: [League]) -> Void) {
        let queryRef = firRef.child("leagues")
        
        queryRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            // this block is called for every result returned
            guard snapshot.exists() else {
                completion([])
                return
            }
            _leagues.removeAll()
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for dict: DataSnapshot in allObjects {
                    guard dict.exists() else { continue }
                    let league = League(snapshot: dict)
                    _leagues[league.id] = league
                }
            }
            print("getLeagues results count: \(_leagues.count)")
            completion(Array(_leagues.values))
        }
    }
    
    func observeUsers(for league: League, completion: ((_ result: [Membership]?, _ error: Error?) -> Void)?) {
        let queryRef = firRef.child("leaguePlayers").child(league.id)
        queryRef.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else { return }
            // return value should be [playerId: status]
            guard let dict = snapshot.value as? [String: String] else { return }
            let roster = dict.compactMap({ (id, status) -> Membership? in
                return Membership(id: id, status: status)
            })
            completion?(roster, nil)
        }
    }

    
    func memberships(for league: League, completion: @escaping (([Membership]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion(nil)
                return
            }
            //print("Players for league results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let roster = dict.compactMap({ (arg) -> Membership? in
                    let (key, val) = arg
                    if let status = val as? String {
                        return Membership(id: key, status: status)
                    } else {
                        return nil
                    }
                })
                completion(roster)
            } else {
                completion([])
            }
        }
    }
    
    func players(for league: League, completion: @escaping (([String]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion(nil)
                return
            }
            //print("Players for league results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let userIds = dict.compactMap({ (arg) -> String? in
                    let (key, val) = arg
                    if let status = val as? String, (status == "member" || status == "owner" || status == "organizer") {
                        return key
                    } else {
                        return nil
                    }
                })
                completion(userIds)
            } else {
                completion([])
            }
        }
    }

    func events(for league: League, completion: @escaping (([Event]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getEventsForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                print("Events for league error \(error)")
                completion(nil)
                return
            }
            print("Events for league results \(result)")
            if let resultDict = result as? [String: Any], let eventDicts = resultDict["result"] as? [String:[String: Any]] {
                var events = [Event]()
                for (key, value) in eventDicts {
                    let event = Event(key: key, dict: value)
                    events.append(event)
                }
                completion(events)
            } else {
                completion([])
            }
        }
    }

    func leagues(for player: Player, completion: @escaping (([String]?)->Void)) {
        FirebaseAPIService().cloudFunction(functionName: "getLeaguesForPlayer", params: ["userId": player.id]) { (result, error) in
            guard error == nil else {
                //print("Leagues for player error \(error)")
                completion(nil)
                return
            }
            //print("Leagues for player results \(result)")
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                let userIds = Array(dict.keys)
                completion(userIds)
            } else {
                completion([])
            }
        }
    }

    func changeLeaguePlayerStatus(playerId: String, league: League, status: String, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        FirebaseAPIService().cloudFunction(functionName: "changeLeaguePlayerStatus", method: "POST", params: ["userId": playerId, "leagueId": league.id, "status": status]) { (result, error) in
            guard error == nil else {
                print("Player status change error \(error)")
                completion(nil, error)
                return
            }
            print("Player status change result \(result)")
            completion(result, nil)
        }
    }

    func withId(id: String, completion: @escaping ((League?)->Void)) {
        if let found = _leagues[id] {
            completion(found)
            return
        }
        
        let ref = firRef.child("leagues")
        ref.child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            
            let league = League(snapshot: snapshot)
            _leagues[id] = league
            completion(league)
        })
    }
}
