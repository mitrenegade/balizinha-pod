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
    
    var subject: String? {
        return feedback.dict?["subject"] as? String
    }
    
    var userId: String? {
        return feedback.dict?["userId"] as? String
    }
    
    var email: String? {
        return feedback.dict?["email"] as? String
    }
    
    var details: String? {
        return feedback.dict?["details"] as? String
    }
    
    var createdAt: String? {
        return feedback.createdAt?.dateString()
    }

    var status: FeedbackStatus {
        guard let statString = feedback.dict["status"] as? String else { return .new }
        guard let stat = FeedbackStatus(rawValue: statString) else { return .new }
        return stat
    }
}

// helpers
extension FeedbackViewModel {
    class var baseRef: Reference {
        return AIRPLANE_MODE ? MockDatabaseReference(snapshot: FeedbackViewModel.mockFeedbackSnapshot) : firRef
    }

    class func checkForFeedback(completion: @escaping ((Bool) -> Void)) {
        let ref: Query
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
        var feedbackDict: [String: Any] = ["createdAt": Date().timeIntervalSince1970 - 3600, "userId": "abc", "subject": "test", "email": "test@gmail.com", "details": "long test message test message long test message test message long test message test message long test message test message"]
        // TO TEST UNREAD messages:
        feedbackDict["status"] = "new"
        return MockDataSnapshot(exists: true, key: "feedback123", value: feedbackDict, ref: nil)
    }
}
