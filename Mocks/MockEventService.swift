//
//  MockEventService.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/18/19.
//

import UIKit
import RenderCloud

public class MockEventService: EventService {
    var reference: Reference
    var apiService: CloudAPIService

    public init() {
        reference = MockDatabaseReference()
        apiService = MockCloudAPIService(uniqueId: "abc", results: ["result": "success"])
        super.init(reference: reference, apiService: apiService)
    }
}
