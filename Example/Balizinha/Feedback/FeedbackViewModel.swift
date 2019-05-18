//
//  FeedbackViewModel.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

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
