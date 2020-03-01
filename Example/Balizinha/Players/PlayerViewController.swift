//
//  PlayerViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/15/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var photoView: RAImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel?
    @IBOutlet weak var activeLabel: UILabel?

    var player: Player?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.refresh()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = PannaUI.navBarTint
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    func refresh() {
        guard let player = self.player else { return }
        
        if let name = player.name {
            self.nameLabel.text = name
        }
        else if let email = player.email {
            self.nameLabel.text = email
        }
        else {
            self.nameLabel.text = nil
        }
        
        if let cityId = player.cityId {
            CityService.shared.withId(id: cityId) { [weak self] (city) in
                if let city = city as? City {
                    self?.cityLabel.text = city.shortString
                } else {
                    self?.cityLabel.text = nil
                }
            }
        }
        else {
            self.cityLabel.text = nil
        }
        
        idLabel.text = player.id
        emailLabel.text = player.email
        if let lat = player.lat, let lon = player.lon {
            var text = "Location: \(lat), \(lon)"
            if let timestamp = player.lastLocationTimestamp {
                let time = timestamp.dateString()
                text = text + "\nActive: " + time
            }
            locationLabel.text = text
        } else {
            locationLabel.text = "No location information available"
        }
        
        if let baseVenueId = player.baseVenueId {
            venueLabel.text = "Loading venue..."
            VenueService.shared.withId(id: baseVenueId) { [weak self] (venue) in
                if let venue = venue as? Venue {
                    self?.venueLabel.text = "\(String(describing: venue.shortString))\n\(venue.id)"
                } else {
                    self?.venueLabel.isHidden = true
                }
            }
        } else {
            venueLabel.isHidden = true
        }
        
        if let notes = player.info {
            self.notesLabel.text = notes
            self.notesLabel.sizeToFit()
        }
        else {
            self.notesLabel.text = nil
        }
        
        versionLabel?.isHidden = true
        if let os = player.os, let version = player.version {
            versionLabel?.text = "Version: \(version) \(os)"
            versionLabel?.isHidden = false
        }

        if let active = player.lastActiveTimestamp {
            activeLabel?.text = active.dateString()
            activeLabel?.alpha = 1
        } else if let active = player.createdAt {
            activeLabel?.text = active.dateString()
            activeLabel?.alpha = 0.5
        } else {
            activeLabel?.isHidden = true
        }

        refreshPhoto()
    }
    
    func refreshPhoto() {
        photoView.layer.cornerRadius = photoView.frame.size.height / 2
        FirebaseImageService().profileUrl(with: player?.id) {[weak self] (url) in
            DispatchQueue.main.async {
                if let url = url {
                    self?.photoView.imageUrl = url.absoluteString
                }
                else {
                    self?.photoView.layer.cornerRadius = 0
                    self?.photoView.imageUrl = nil
                    self?.photoView.image = UIImage(named: "profile-img")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
