//
//  FeedItemCell.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class FeedItemCell: UITableViewCell {
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelId: UILabel!
    @IBOutlet weak var labelCreated: UILabel!
    
    @IBOutlet weak var imagePhoto: RAImageView?

    func configure(feedItem: FeedItem) {
        labelMessage.text = ".."
        let message = feedItem.message ?? feedItem.defaultMessage
        if let userId = feedItem.userId {
            PlayerService.shared.withId(id: userId) { [weak self] (player) in
                let name = player?.name ?? player?.email ?? "Anon"
                self?.labelMessage.text = "\(name): \(message)"
            }
        } else {
            labelMessage.text = message
        }
        labelId.text = feedItem.id
        labelCreated.text = feedItem.createdAt?.dateString()

        if feedItem.hasPhoto {
            FirebaseImageService().feedItemPhotoUrl(with: feedItem.id) {[weak self] (url) in
                DispatchQueue.main.async {
                    if let urlString = url?.absoluteString {
                        self?.imagePhoto?.imageUrl = urlString
                    } else {
                        self?.imagePhoto?.imageUrl = nil
                        self?.imagePhoto?.image = nil
                    }
                }
            }
        }
    }
}
