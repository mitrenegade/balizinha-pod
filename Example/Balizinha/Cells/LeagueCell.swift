//
//  LeagueCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import AsyncImageView
import RxSwift
import Balizinha

class LeagueCell: UITableViewCell {
    @IBOutlet weak var icon: AsyncImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelPointCount: UILabel!
    @IBOutlet weak var labelPlayerCount: UILabel!
    @IBOutlet weak var labelGameCount: UILabel!
    @IBOutlet weak var labelRatingCount: UILabel!
    @IBOutlet weak var labelCity: UILabel! // privacy also
    @IBOutlet weak var labelTags: UILabel! // level and other status strings
    @IBOutlet weak var labelInfo: UILabel! // catch phrase

    var disposeBag: DisposeBag = DisposeBag()
    
    func configure(league: League) {
        disposeBag = DisposeBag()
        icon.image = nil
        if let url = league.photoUrl {
            icon.imageURL = URL(string: url)
        } else {
            icon.imageURL = nil
            icon.image = UIImage(named: "crest30")?.withRenderingMode(.alwaysTemplate)
            icon.tintColor = UIColor.white
            icon.backgroundColor = UIColor.darkGreen
        }
        labelName.text = league.name ?? "Unknown league"
        labelCity.text = league.city ?? "Location unspecified"
        labelTags.text = league.tagString
        if !league.info.isEmpty {
            labelInfo.text = "\"\(league.info)\""
        } else {
            labelInfo.text = nil
        }
        
        let pointCount = league.pointCount
        let rating = 0 //league.rating
        
        // player count
        LeagueService.shared.players(for: league) { [weak self] (ids) in
            DispatchQueue.main.async {
                self?.labelPlayerCount.text = "\(ids?.count ?? 0)"
            }
        }
        
        // eventCount
        LeagueService.shared.events(for: league) { [weak self] (ids) in
            DispatchQueue.main.async {
                self?.labelGameCount.text = "\(ids?.count ?? 0)"
            }
        }
        
        labelPointCount.text = "\(pointCount)"
        labelRatingCount.text = String(format: "%1.1f", rating)
        
        // privacy
        if league.isPrivate {
            labelCity.text = "Private"
            labelTags.isHidden = true
            labelInfo.isHidden = true
            
            icon.alpha = 0.5
            labelName.alpha = 0.5
            labelCity.alpha = 0.5
        } else {
            labelTags.isHidden = false
            labelInfo.isHidden = false
            icon.alpha = 1
            labelName.alpha = 1
            labelCity.alpha = 1
        }
    }
}
