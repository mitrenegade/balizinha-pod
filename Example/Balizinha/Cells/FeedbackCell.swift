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
    @IBOutlet weak var constraintLabelHeight: NSLayoutConstraint!
    func configure(feedback: FirebaseBaseModel) {
        guard let dict = feedback.dict else { return }
        labelSubject.text = dict["subject"] as? String
        labelUser.text = dict["userId"] as? String
        labelEmail.text = dict["email"] as? String
        labelDetails.text = dict["details"] as? String

        labelDetails.sizeToFit()
        constraintLabelHeight.constant = max(40, labelDetails.frame.size.height)
        
        labelDate.text = feedback.createdAt?.dateString()
    }
}
