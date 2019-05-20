//
//  MockVenueService.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import RenderCloud

// this service retains memory
public class MockVenueService: VenueService {
    init() {
        super.init()
        cities = [City(key: "123", dict: ["createdAt": Date().timeIntervalSince1970 - 3600, "name": "skyville", "state": "Cloud", "lat": 39, "lon": -122])]
    }
    
    override public func getCities(completion: (([City]) -> Void)?) {
        completion?(cities)
    }
    
    override public func createCity(_ name: String, state: String?, lat: Double?, lon: Double?, completion: @escaping (City?, NSError?) -> Void) {
        completion(nil, nil)
    }
}

