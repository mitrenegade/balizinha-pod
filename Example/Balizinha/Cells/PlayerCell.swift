//
//  PlayerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha

class PlayerCell: UITableViewCell {
    @IBOutlet weak var imagePhoto: RAImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelId: UILabel?
    @IBOutlet weak var labelCreated: UILabel?
    @IBOutlet weak var labelDetails: UILabel?
    
    // photo constraints
    @IBOutlet weak var constraintImageWidth: NSLayoutConstraint?
    @IBOutlet weak var constraintNameLeftOffset: NSLayoutConstraint?
    @IBOutlet weak var constraintNameTopOffset: NSLayoutConstraint?
    
    // detail constraints
    @IBOutlet weak var constraintDetailHeight: NSLayoutConstraint?

    func configure(player: Player, expanded: Bool, url: String?) {
        labelName.text = player.name ?? player.email ?? "Anon"
        labelId?.text = player.id
        labelCreated?.text = player.createdAt?.dateString()

        if let urlString = url {
            if expanded {
                constraintImageWidth?.constant = frame.size.width - 30
                constraintNameLeftOffset?.constant = 15
                constraintNameTopOffset?.constant = frame.size.width - 30
                
            } else {
                constraintImageWidth?.constant = 50
                constraintNameLeftOffset?.constant = 15 + 50 + 8
                constraintNameTopOffset?.constant = 0
            }
            updatePhoto(urlString: urlString)
        } else {
            constraintImageWidth?.constant = 0
            constraintNameLeftOffset?.constant = 15
            constraintNameTopOffset?.constant = 0
        }
        
        var detailText: String = ""
        if let email = player.email {
            detailText = detailText + "Email: \(email)\n"
        }
        if let city = player.city {
            detailText = detailText + "City: \(city)\n"
        }
        if let info = player.info {
            detailText = detailText + "Info: \(info)\n"
        }
        if let lat = player.lat, let lon = player.lon, let active = player.lastLocationTimestamp {
            let time = active.dateString()
            detailText = detailText + "Location: \(lat), \(lon)\nActive: \(time)"
        }
        if let details = labelDetails {
            details.text = detailText
            let bounds = (detailText as NSString).size(withAttributes: [NSAttributedString.Key.font: details.font])
            if expanded {
                constraintDetailHeight?.constant = bounds.height + 50
            } else {
                constraintDetailHeight?.constant = 0
            }
        }
    }
    
    func updatePhoto(urlString: String) {
        imagePhoto.image = nil
        imagePhoto.imageUrl = urlString
    }

    func reset() {
        labelName.text = nil
        labelId?.text = nil
        labelCreated?.text = nil
    }
}
