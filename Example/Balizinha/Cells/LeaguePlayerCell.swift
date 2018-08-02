//
//  LeaguePlayerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/7/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import AsyncImageView

class LeaguePlayerCell: UITableViewCell {
    @IBOutlet weak var imagePhoto: AsyncImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelId: UILabel?
    @IBOutlet weak var labelCreated: UILabel!

    @IBOutlet weak var labelStatus: UILabel?
    
    func configure(player: Player, status: Membership.Status) {
        labelName.text = player.name ?? player.email ?? "Anon"
        labelId?.text = player.id
        labelCreated.text = player.createdAt?.dateString()
        
        if let urlString = player.photoUrl {
            self.updatePhoto(urlString: urlString)
        }
        
        labelStatus?.text = status.rawValue
        switch status {
        case .organizer:
            labelStatus?.textColor = UIColor.blue
        case .member:
            labelStatus?.textColor = UIColor.green
        case .none:
            labelStatus?.textColor = UIColor.red
        }
    }
    
    func updatePhoto(urlString: String) {
        imagePhoto.image = nil
        imagePhoto.showActivityIndicator = true
        guard let url = URL(string: urlString) else { return }
        imagePhoto.imageURL = url
    }
    
    func reset() {
        labelName.text = nil
        labelId?.text = nil
        labelCreated.text = nil
    }
}
