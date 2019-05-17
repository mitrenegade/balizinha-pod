//
//  VenuesListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/16/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Firebase
import Balizinha
import RenderCloud

class VenuesListViewController: ListViewController {
    var cities: [City] = []
    var venues: [Venue] = [] // not used
    var service: VenueService?
    var reference: Reference?
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Venues"
        service = VenueService.shared
        reference = firRef

        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }

    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel? {
        return City(snapshot: snapshot)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "toPlayers", let controller = segue.destination as? EventPlayersViewController {
//            controller.event = sender as? Balizinha.Event
//        }
//    }
}

extension VenuesListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Venues"
        }
        return "Cities"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return venues.count
        }
        return cities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        
        if indexPath.section == 0 {
            let array = venues
            if indexPath.row < array.count {
                let venue = array[indexPath.row]
                cell.textLabel?.text = venue.name ?? ""
                cell.detailTextLabel?.text = venue.city ?? ""
            }
        } else {
            let array = venues
            if indexPath.row < array.count {
                let city = array[indexPath.row]
                cell.textLabel?.text = city.name ?? ""
                cell.detailTextLabel?.text = "\(city.lat ?? 0), \(city.lon ?? 0)"
            }
        }
        return cell
    }
}
