//
//  LeaguePlayerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/7/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha

class LeaguePlayerCell: UITableViewCell {
    @IBOutlet weak var imagePhoto: RAImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelEmail: UILabel?
    @IBOutlet weak var labelCreated: UILabel?
    @IBOutlet weak var labelInitials: UILabel!
    @IBOutlet weak var labelId: UILabel?
    @IBOutlet weak var labelStatus: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelInitials.textColor = PannaUI.cellText
        labelInitials.layer.borderWidth = 2
        labelInitials.layer.borderColor = PannaUI.cellBorder.cgColor
        labelInitials.textAlignment = .center
    }
    
    func configure(player: Player, status: Membership.Status?) {
        labelName.text = player.name ?? "Anon"
        labelEmail?.text = player.email
        labelCreated?.text = player.createdAt?.dateString()
        labelId?.text = player.id
        if let status = status {
            labelStatus?.text = status.rawValue
        }
        
        imagePhoto.image = nil
        imagePhoto.layer.cornerRadius = imagePhoto.frame.size.height / 2
        labelInitials.layer.cornerRadius = labelInitials.frame.size.height / 2
        labelInitials.font = UIFont.systemFont(ofSize: imagePhoto.frame.size.width / 2)
        FirebaseImageService().profileUrl(with: player.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let url = url {
                    self?.imagePhoto.imageUrl = url.absoluteString
                    self?.imagePhoto.isHidden = false
                    self?.labelInitials.isHidden = true
                } else if let name = player.name, let char = name.uppercased().first {
                    self?.labelInitials.text = String(char)
                    self?.imagePhoto.isHidden = true
                    self?.labelInitials.isHidden = false
                }
            }
        }
        
        labelId?.text = player.id
        labelEmail?.text = player.email
    }
    
    func reset() {
        labelName.text = nil
        labelEmail?.text = nil
        labelCreated?.text = nil
        labelId?.text = nil
        labelInitials.text = nil
        imagePhoto.image = nil
        imagePhoto.imageUrl = nil
    }
}
