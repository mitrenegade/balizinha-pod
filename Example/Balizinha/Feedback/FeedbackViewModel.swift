//
//  FeedbackViewModel.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import RenderCloud

enum FeedbackStatus: String {
    case new
    case read
}

class FeedbackViewModel: NSObject {
    let feedback: FirebaseBaseModel!
    init(feedbackObject: FirebaseBaseModel) {
        feedback = feedbackObject
    }
    
    var status: FeedbackStatus {
        guard let statString = feedback.dict["status"] as? String else { return .new }
        guard let stat = FeedbackStatus(rawValue: statString) else { return .new }
        return stat
    }
}

// helpers
extension FeedbackViewModel {
    class func checkForFeedback(completion: @escaping ((Bool) -> Void)) {
        let ref: Query
        let baseRef: Reference = AIRPLANE_MODE ? MockDatabaseReference(snapshot: FeedbackViewModel.mockFeedbackSnapshot) : firRef
        ref = baseRef.child(path: "feedback").queryOrdered(by: "createdAt")
        ref.observeSingleValue() {(snapshot) in
            guard snapshot.exists() else { completion(false); return }
            if let allObjects = snapshot.allChildren {
                for dict: Snapshot in allObjects {
                    let viewModel = FeedbackViewModel(feedbackObject: FirebaseBaseModel(snapshot: dict))
                    if viewModel.status == .new {
                        completion(true)
                        return
                    }
                }
            }
            completion(false)
        }
    }
    
    private class var mockFeedbackSnapshot: Snapshot {
        return MockDataSnapshot(exists: true, key: "feedback", value: nil, ref: nil)
    }
}
