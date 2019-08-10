//
//  LeagueService.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/10/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseCore
import FirebaseDatabase
import RenderCloud

fileprivate var _leagues: [String: League] = [:]
fileprivate var _playerLeagues: [String: Membership.Status] = [:]

public class LeagueService: NSObject {
    public static let shared: LeagueService = LeagueService()
    fileprivate var disposeBag: DisposeBag
    public var featuredLeagueId: String?

    public override init() {
        disposeBag = DisposeBag()
        super.init()
        
        PlayerService.shared.current.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] player in
            guard let player = player else { return }
            self?.leagueMemberships(for: player, completion: {_ in
                // no op
            })
        }).disposed(by: disposeBag)
    }

    public class func resetOnLogout() {
        shared.disposeBag = DisposeBag()
        _playerLeagues = [:]
        shared.featuredLeagueId = nil
    }

    // MARK: - League creation
    public func create(name: String, city: String, info: String, completion: @escaping ((_ result: Any?, _ error: Error?)->Void)) {
        guard let user = AuthService.currentUser else { return }
        let params = ["name": name, "city": city, "info": info, "userId": user.uid]
        RenderAPIService().cloudFunction(functionName: "createLeague", method: "POST", params: params, completion: { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        })
    }
    
    // MARK: - League membership
    public func join(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        RenderAPIService().cloudFunction(functionName: "joinLeaveLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": true]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }
    
    public func leave(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        RenderAPIService().cloudFunction(functionName: "joinLeaveLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": false]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }

    // MARK: League info
    public func withId(id: String, completion: @escaping ((League?)->Void)) {
        if let found = _leagues[id] {
            completion(found)
            return
        }
        
        let ref = firRef.child("leagues").child(id)
        ref.observe(.value) { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            ref.removeAllObservers()
            let league = League(snapshot: snapshot)
            _leagues[id] = league
            completion(league)
        }
    }
    
    // MARK: league deletion
    public class func delete(_ league: League) {
        let id = league.id
        let queryRef = firRef.child("leagues").child(id)
        queryRef.setValue(nil)
        
        let playersRef = firRef.child("leaguePlayers").child(id)
        playersRef.setValue(nil)
    }

    /**
    Returns all currently cached leagues, in no particular order, in array format
    */
    public var allLeagues: [League] {
        return Array(_leagues.values)
    }
    
    // MARK: - Cloud functions
    // TODO: is this used?
    public func getLeagues(completion: @escaping (_ results: [League]) -> Void) {
        let queryRef = firRef.child("leagues")
        queryRef.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
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
            completion(Array(_leagues.values))
        }
    }

    // MARK: Leagues for player
    public func leagueMemberships(for player: Player, completion: @escaping (([String: Membership.Status]?)->Void)) {
        RenderAPIService().cloudFunction(functionName: "getLeaguesForPlayer", params: ["userId": player.id]) { (result, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            if let dict = (result as? [String: Any])?["result"] as? [String: Any] {
                var result = [String:Membership.Status]()
                for (leagueId, statusString) in dict {
                    var status = statusString as? String ?? "none"
                    // for api v1.4, some users were set to true
                    if let legacyValue = statusString as? Bool, legacyValue == true {
                        status = "member"
                    }
                    if let membershipStatus = Membership.Status(rawValue: status) {
                        result[leagueId] = membershipStatus
                    }
                }
                _playerLeagues = result
                completion(result)
            } else {
                completion([:])
            }
        }
    }

    public func changeLeaguePlayerStatus(playerId: String, league: League, status: String, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        RenderAPIService().cloudFunction(functionName: "changeLeaguePlayerStatus", method: "POST", params: ["userId": playerId, "leagueId": league.id, "status": status]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }
    
    // MARK: Players for league
    public func memberships(for league: League, completion: @escaping (([Membership]?)->Void)) {
        RenderAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
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
    
    // TODO: is this the same?
    public func players(for league: League, completion: @escaping (([String:Membership.Status])->Void)) {
        RenderAPIService().cloudFunction(functionName: "getPlayersForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                //print("Players for league error \(error)")
                completion([:])
                return
            }
            var memberships: [String: Membership.Status] = [:]
            if let dict = (result as? [String: Any])?["result"] as? [String: String] {
                for (key, val) in dict {
                    let membership = Membership(id: key, status: val)
                    if membership.isActive {
                        memberships[key] = membership.status
                    }
                }
            }
            completion(memberships)
        }
    }
    
    // MARK: - Events for league
    public func events(for league: League, completion: @escaping (([Event]?)->Void)) {
        RenderAPIService().cloudFunction(functionName: "getEventsForLeague", params: ["leagueId": league.id]) { (result, error) in
            guard error == nil else {
                completion(nil)
                return
            }
            if let resultDict = result as? [String: Any], let eventDicts = resultDict["result"] as? [String:[String: Any]] {
                var events = [Event]()
                for (key, value) in eventDicts {
                    let event = Event(key: key, dict: value)
                    guard event.isActive || event.isCancelled else { return }
                    EventService.shared.cache(event)
                    events.append(event)
                }
                completion(events)
            } else {
                completion([])
            }
        }
    }

    // MARK: - Subscriptions
    public func getOwnerLeaguesAndSubscriptions(completion: ((Any?, Error?)->Void)?) {
        guard let user = AuthService.currentUser else { return }
        let params = ["userId": user.uid]
        RenderAPIService().cloudFunction(functionName: "getOwnerLeaguesAndSubscriptions", method: "POST", params: params, completion: { (result, error) in
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            // parse leagues
            var leagues: [League] = []
            if let resultDict = result as? [String: Any], let leagueDict = resultDict["leagues"] as? [String: [String: Any]] {
                for (key, dict) in leagueDict {
                    let league = League(key: key, dict: dict)
                    leagues.append(league)
                    // TODO: add caching
                    //                    LeagueService.shared.cache(league)
                }
            }
            
            // TODO: parse subscriptions
            
            completion?([], nil)
        })
    }
    
    // MARK: - Cached info
    // League/Player info using cached data
    public func playerIsIn(league: League) -> Bool {
        guard let status = _playerLeagues[league.id] else { return false }
        return status != Membership.Status.none
    }
    
    public func playerIsOrganizerForAnyLeague() -> Bool {
        return _playerLeagues.filter{ $0.value == Membership.Status.organizer }.isEmpty == false
    }
    
    public var ownerLeagues: [League] {
        guard let ownerId = PlayerService.shared.current.value?.id else { return [] }
        var leagues: [League] = []
        for league in allLeagues {
            if league.ownerId == ownerId{
                leagues.append(league)
            }
        }
        return leagues
    }
}
