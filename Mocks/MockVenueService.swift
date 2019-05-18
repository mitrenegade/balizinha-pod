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
    var cities: [String: Any]
    init() {
        cities =
            ["123":
                ["createdAt": Date().timeIntervalSince1970 - 3600, "name": "skyville", "state": "Cloud", "lat": 39, "lon": -122]
            ]
    }
    
    override public func getCities(completion: (([City]) -> Void)?) {
        var results: [City] = cities
        for (key, val) in objectsDict {
            if let dict = val as? [String: Any] {
                let object = Balizinha.City(key: key, dict: dict)
                results.append(object)
            }
        }
    }
    
    override public func createCity(_ name: String, state: String?, lat: Double?, lon: Double?, completion: @escaping (City?, NSError?) -> Void) {
        completion(nil, nil)
    }
}
