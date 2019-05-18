//
//  MockVenueService.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import RenderCloud

// this service retains memory
class MockVenueService {
    public class var shared: VenueService {
        return VenueService(reference: MockDatabaseReference(snapshot: MockVenueService.mockSnapshot), apiService: MockVenueService.mockAPIService)
    }
    
    private class var cities: [String: Any] {
        return ["results":
            ["123":
                ["createdAt": Date().timeIntervalSince1970 - 3600, "name": "skyville", "state": "Cloud", "lat": 39, "lon": -122]
            ]
        ]
    }
    private class var mockAPIService: MockCloudAPIService {
        let mockCities = cities
        return MockCloudAPIService(uniqueId: "123", results: mockCities)
    }
    private class var mockSnapshot: Snapshot {
        let dict: [String: Any] = cities
        return MockDataSnapshot(exists: true, key: "abc", value: dict, ref: nil)
    }

}
