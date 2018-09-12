//
//  EventCell.swift
//  Balizinha_Example
//
//  Created by Ren, Bobby on 8/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class EventCell: UITableViewCell {
    @IBOutlet var labelFull: UILabel!
    @IBOutlet var labelAttendance: UILabel!
    @IBOutlet var labelLocation: UILabel!
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelTimeDate: UILabel!
    @IBOutlet var eventLogo: RAImageView!
    @IBOutlet weak var labelID: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var event: Balizinha.Event?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.eventLogo.layer.cornerRadius = self.eventLogo.frame.size.height / 2
        self.eventLogo.layer.borderWidth = 1.0
        self.eventLogo.layer.masksToBounds = true
        self.eventLogo.contentMode = .scaleAspectFill
    }
    
    func setup(with event: Balizinha.Event) {
        self.event = event
        labelID.text = event.id
        let name = event.name ?? "Balizinha"
        let type = event.type.rawValue
        self.labelName.text = "\(name) (\(type))"
        if let startTime = event.startTime {
            self.labelTimeDate.text = "\(event.dateString(startTime)) \(event.timeString(startTime))"
        }
        else {
            self.labelTimeDate.text = "Date/Time TBD"
        }
        let place = event.place
        self.labelLocation.text = place
        
        // TODO this is too layered, how to check for either url without doing so many web requests? so many if/else?
        FirebaseImageService().eventPhotoUrl(for: event) { [weak self] (url) in
            DispatchQueue.main.async {
                if let urlString = url?.absoluteString {
                    self?.eventLogo.imageUrl = urlString
                } else if let leagueId = event.league {
                    FirebaseImageService().leaguePhotoUrl(for: leagueId) { [weak self] (url) in
                        DispatchQueue.main.async {
                            if let urlString = url?.absoluteString {
                                self?.eventLogo.imageUrl = urlString
                            } else {
                                self?.eventLogo.imageUrl = nil
                                self?.eventLogo.image = UIImage(named: "soccer")
                            }
                        }
                    }
                } else {
                    self?.eventLogo.imageUrl = nil
                    self?.eventLogo.image = UIImage(named: "soccer")
                }
            }
        }
        
        let containsUser: Bool
        if let player = PlayerService.shared.current.value {
            containsUser = event.containsPlayer(player)
        } else {
            containsUser = false
        }
        
        if !event.isPast {
            // Button display and action
            
            if !event.active {
                labelFull.text = "Event deleted"
                return
            } else if self.event!.userIsOrganizer {
                self.labelFull.text = "This is your event."
            }
            else if containsUser {
                self.labelFull.text = "You're going!" //To-Do: Add functionality whether or not event is full
            }
            else {
                if self.event!.isFull {
                    self.labelFull.text = "Event full"
                }
                else {
                    self.labelFull.text = "Available"
                }
            }
            self.labelAttendance.text = "\(self.event!.numPlayers)"
        } else {
            if !event.active {
                labelFull.text = "Event deleted"
                return
            } else {
                self.labelFull.isHidden = true
            }
            self.labelAttendance.text = "\(self.event!.numPlayers)"
        }
    }
}
