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
    public init() {
        super.init()
        cities = [City(key: "123", dict: ["createdAt": Date().timeIntervalSince1970 - 3600, "name": "Skyville", "state": "Cloud", "lat": 39, "lon": -122])]
    }
    
    override public func getCities(completion: (([City]) -> Void)?) {
        completion?(cities)
    }
    
    override public func createCity(_ name: String, state: String?, lat: Double?, lon: Double?, completion: @escaping (City?, NSError?) -> Void) {
        let id = RenderAPIService().uniqueId()
        let city = City(key: id, dict: ["createdAt": Date().timeIntervalSince1970 - 3600, "name": name, "state": state, "lat": lat ?? 0, "lon": lon ?? 0])
        cities.append(city)
        completion(city, nil)
    }
}
