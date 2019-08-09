//
//  MockService.swift
//  Panna
//
//  Created by Bobby Ren on 7/17/19.
//  Copyright © 2019 Bobby Ren. All rights reserved.
//

import RenderCloud

public class MockService: NSObject {
    //***************** hack: for test purposes only
    public class func randomLeague() -> League {
        let league = League()
        league.dict = ["name": "My Awesome League", "city": MockService.randomPlace(), "tags": "fake, league", "info": "this is my airplane league"]
        return league
    }
    
    fileprivate class func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
    
    public static func mockLeague() -> League {
        return League(key: "abc", dict: ["name": "My league", "city": "Philadelphia", "info": "Airplane mode league", "ownerId": "1"])
    }

    public static func mockPlayerOrganizer() -> Player {
        return Player(key: "1", dict: ["name":"Philly Phanatic", "city": "Philadelphia", "email": "test@gmail.com"])
    }

    public static func mockPlayerMember() -> Player {
        return Player(key: "2", dict: ["name":"Gritty", "city": "Philadelphia", "email": "grittest@gmail.com"])
    }

    public static func mockEventService() -> EventService {
        let eventDict: [String: Any] = ["name": "Test event",
                                        "status": "active",
                                        "startTime": (Date().timeIntervalSince1970 + Double(Int(arc4random_uniform(72)) * 3600))]
        let referenceSnapshot = MockDataSnapshot(exists: true,
                                                 key: "1",
                                                 value: eventDict,
                                                 ref: nil)
        let reference = MockDatabaseReference(snapshot: referenceSnapshot)
        let apiService = MockCloudAPIService(uniqueId: "abc", results: ["success": true])
        return EventService(reference: reference, apiService: apiService)
    }
}
