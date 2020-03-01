//
//  MockVenueService.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import RenderCloud

// this service retains memory
public class MockCityService: CityService {
    public init() {
        super.init(reference: MockDatabaseReference(), apiService: MockCloudAPIService(uniqueId: "abc", results: ["success":true]))
        _cities = [City(key: "123", dict: ["createdAt": Date().timeIntervalSince1970 - 3600, "name": "Skyville", "state": "Cloud", "lat": 39, "lon": -122])]
    }
    
    override public func getCities(completion: (([City]) -> Void)?) {
        completion?(_cities)
    }
    
    override public func createCity(_ name: String, state: String?, lat: Double?, lon: Double?, completion: @escaping (City?, NSError?) -> Void) {
        let id = RenderAPIService().uniqueId()
        let dict: [String: Any] = ["createdAt": Date().timeIntervalSince1970 - 3600, "name": name, "state": state ?? "", "lat": lat ?? 0, "lon": lon ?? 0]
        let city = City(key: id, dict: dict)
        _cities.append(city)
        completion(city, nil)
    }
}

