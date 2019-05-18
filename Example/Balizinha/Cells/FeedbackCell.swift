//
//  FeedbackCell.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class FeedbackCell: UITableViewCell {
    
    @IBOutlet weak var labelSubject: UILabel!
    @IBOutlet weak var labelUser: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelDetails: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelNew: UILabel!
    
    @IBOutlet weak var constraintLabelHeight: NSLayoutConstraint!
    func configure(feedback: FirebaseBaseModel) {
        guard let dict = feedback.dict else { return }
        let model = FeedbackViewModel(feedbackObject: feedback)
        labelSubject.text = model.subject
        labelUser.text = model.userId
        labelEmail.text = model.email
        labelDetails.text = model.details

//        labelDetails.sizeToFit()
//        constraintLabelHeight.constant = max(20, labelDetails.frame.size.height)
        labelDate.text = model.createdAt

        switch model.status {
        case .new:
            labelNew.isHidden = false
            labelNew.text = "NEW"
        default:
            labelNew.isHidden = true
        }
    }
}
