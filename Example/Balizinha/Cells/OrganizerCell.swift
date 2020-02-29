//
//  OrganizerCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/5/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha

class OrganizerCell: UITableViewCell {
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var photoView: RAImageView?
    var organizerId: String?
    var player: Player?

    func configure(organizer: Organizer) {
        organizerId = organizer.id
        photoView?.image = nil

        guard let id = organizerId else { return }
        PlayerService.shared.withId(id: id, completion: { [weak self] (player) in
            guard let organizerId = self?.organizerId, let player = player as? Player, player.id == organizerId else { return }
            
            self?.labelText.text = player.name ?? player.email ?? player.id
            self?.labelText.sizeToFit()
            
            self?.refreshPhoto(oldUrl: player.photoUrl, currentId: id)
            
            self?.labelStatus.text = organizer.status.rawValue
            self?.labelDate.text = organizer.createdAt?.dateString()
        })
    }
    
    func refreshPhoto(oldUrl: String?, currentId: String) {
        guard let photoView = self.photoView else { return }
        photoView.layer.cornerRadius = photoView.frame.size.width / 4
        photoView.clipsToBounds = true
        photoView.contentMode = .scaleAspectFill
        FirebaseImageService().profileUrl(with: currentId) {[weak self] (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString {
                    self?.photoView?.imageUrl = urlString
                } else {
                    self?.photoView?.imageUrl = oldUrl
                }
            }
        }
    }
}
