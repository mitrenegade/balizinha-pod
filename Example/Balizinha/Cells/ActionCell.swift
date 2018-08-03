//
//  ActionCell.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/8/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class ActionCell: UITableViewCell {
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var photoView: RAImageView?
    @IBOutlet weak var constraintLabelHeight: NSLayoutConstraint!
    var actionId: String?

    func configure(action: Action) {
        self.labelText.text = ActionViewModel(action: action).displayString
        self.labelText.sizeToFit()
        self.constraintLabelHeight.constant = max(40, self.labelText.frame.size.height)
        
        guard let userId = action.userId else { return }
        
        let actionId = action.id
        self.actionId = actionId
        self.refreshPhoto(userId: userId, currentActionId: actionId)

        labelDate.text = action.createdAt?.dateString()
    }
    
    func refreshPhoto(userId: String, currentActionId: String) {
        guard let photoView = self.photoView else { return }
        photoView.layer.cornerRadius = photoView.frame.size.width / 4
        photoView.clipsToBounds = true
        photoView.contentMode = .scaleAspectFill
        FirebaseImageService().profileUrl(for: userId) { (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString, self.actionId == currentActionId  {
                    photoView.imageUrl = urlString
                }
                else {
                    photoView.imageUrl = nil
                    photoView.image = UIImage(named: "profile-img")
                }
            }
        }
    }
}
