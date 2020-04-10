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
import PannaPay

public class LeagueService: BaseService {
    public static let shared: LeagueService = LeagueService()
    fileprivate var _playerLeagues: [String: Membership.Status] = [:]
    fileprivate var _ownerLeagues: [String] = []
    
    fileprivate var disposeBag: DisposeBag
    public var featuredLeagueId: String?

    public override init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        disposeBag = DisposeBag()
        super.init()
        
        PlayerService.shared.current.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] player in
            guard let player = player else { return }
            self?.leagueMemberships(for: player, completion: {_ in
                // no op
            })
        }).disposed(by: disposeBag)
    }

    public override func resetOnLogout() {
        super.resetOnLogout()
        disposeBag = DisposeBag()
        featuredLeagueId = nil
        readWriteQueue2.async(flags: .barrier) { [weak self] in
            self?._playerLeagues = [:]
            self?._ownerLeagues = []
        }
    }
    
    override var refName: String {
        return "leagues"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return League(snapshot: snapshot)
    }

    // MARK: - League creation
    public func create(name: String, city: String, info: String, completion: @escaping ((_ result: Any?, _ error: Error?)->Void)) {
        guard let user = AuthService.currentUser else { return }
        let params = ["name": name, "city": city, "info": info, "userId": user.uid]
        apiService.cloudFunction(functionName: "createLeague", method: "POST", params: params, completion: { (result, error) in
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
        apiService.cloudFunction(functionName: "joinLeaveLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": true]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }
    
    public func leave(league: League, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        guard let user = AuthService.currentUser else { return }
        apiService.cloudFunction(functionName: "joinLeaveLeague", method: "POST", params: ["userId": user.uid, "leagueId": league.id, "isJoin": false]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }

    // MARK: league deletion
    public class func delete(_ league: League) {
        let id = league.id
        if let queryRef: DatabaseReference = shared.baseRef.child(path: "leagues").child(path: id) as? DatabaseReference {
            queryRef.setValue(nil)
        }
        
        if let playersRef: DatabaseReference = shared.baseRef.child(path: "leaguePlayers").child(path: id) as? DatabaseReference {
            playersRef.setValue(nil)
        }
    }

    /**
    Returns all currently cached leagues, in no particular order, in array format
    */
    public var allLeagues: [League] {
        return getCachedObjects()
    }
    
    // MARK: - Cloud functions
    // TODO: is this used?
    public func getLeagues(completion: @escaping (_ results: [League]) -> Void) {
        let queryRef = baseRef.child(path:"leagues")
        queryRef.observeSingleValue { [weak self] (snapshot) in
            guard snapshot.exists() else {
                return
            }
            var results: [League] = []
            if let allObjects =  snapshot.allChildren {
                for dict: Snapshot in allObjects {
                    guard dict.exists() else { continue }
                    let league = League(snapshot: dict)
                    self?.cache(league)
                    results.append(league)
                }
            }
            completion(results)
        }
    }

    // MARK: Leagues for player
    public func leagueMemberships(for player: Player, completion: @escaping (([String: Membership.Status]?)->Void)) {
        apiService.cloudFunction(functionName: "getLeaguesForPlayer", method: "POST", params: ["userId": player.id]) { [weak self] (result, error) in
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
                self?.readWriteQueue2.async(flags: .barrier) { [weak self] in
                    self?._playerLeagues = result
                }
                completion(result)
            } else {
                completion([:])
            }
        }
    }

    public func changeLeaguePlayerStatus(playerId: String, league: League, status: String, completion: @escaping ((_ result: Any?, _ error: Error?) -> Void)) {
        apiService.cloudFunction(functionName: "changeLeaguePlayerStatus", method: "POST", params: ["userId": playerId, "leagueId": league.id, "status": status]) { (result, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            completion(result, nil)
        }
    }
    
    // MARK: Players for league
    public func memberships(for league: League, completion: @escaping (([Membership]?)->Void)) {
        apiService.cloudFunction(functionName: "getPlayersForLeague", method: "POST", params: ["leagueId": league.id]) { (result, error) in
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
        apiService.cloudFunction(functionName: "getPlayersForLeague", method: "POST", params: ["leagueId": league.id]) { (result, error) in
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
        apiService.cloudFunction(functionName: "getEventsForLeague", method: "POST", params: ["leagueId": league.id]) { (result, error) in
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

    // MARK: - Owner leagues
    public func getOwnerLeagueIds(for player: Player, completion: (([String: Any]?)->Void)?) {
        let queryRef = baseRef.child(path:"ownerLeagues").child(path: player.id)
        queryRef.observeSingleValue { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion?(nil)
                return
            }
            let dict = snapshot.value as? [String: Bool]
            self?.readWriteQueue2.sync {
                self?._ownerLeagues = dict?.compactMap{ $0.key } ?? []
            }
            completion?(dict)
        }
    }
    
    public func getOwnerLeagues(completion: @escaping (([League])->Void)) {
        var leagues: [League] = []
        let group = DispatchGroup()
        var ownerLeagueIds: [String] = []
        readWriteQueue2.sync {
            ownerLeagueIds = _ownerLeagues
        }
        for leagueId in ownerLeagueIds {
            group.enter()
            LeagueService.shared.withId(id: leagueId) { (result) in
                if let league = result as? League {
                    leagues.append(league)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(leagues)
        }
    }
    
    // MARK: - Cached info
    // League/Player info using cached data
    public func playerIsIn(league: League) -> Bool {
        var status: Membership.Status = .none
        readWriteQueue2.sync { [weak self] in
            if let playerStatus = self?._playerLeagues[league.id] {
                status = playerStatus
            }
        }
        return status != Membership.Status.none
    }
    
    public func playerIsOrganizerForAnyLeague() -> Bool {
        var playerStatus: [String: Membership.Status] = [:]
        readWriteQueue2.sync { [weak self] in
            playerStatus = self?._playerLeagues ?? [:]
        }
        return playerStatus.filter{ $0.value == Membership.Status.organizer }.isEmpty == false
    }
    
    public func playerIsOwnerForAnyLeague() -> Bool {
        return !_ownerLeagues.isEmpty
    }

}
