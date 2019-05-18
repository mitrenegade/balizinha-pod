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

    override var refName: String {
        return "cities"
    }

    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel? {
        return City(snapshot: snapshot)
    }
    
    override func load() {
        super.load()
        reloadTable()
    }
}

extension VenuesListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Venues"
        }
        return "Cities"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return objects.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
//            let array = venues
//            if indexPath.row < array.count {
//                let venue = array[indexPath.row]
//                cell.textLabel?.text = venue.name ?? ""
//                cell.detailTextLabel?.text = venue.city ?? ""
//            }
            return UITableViewCell()
        } else {
            let array = objects
            if indexPath.row < array.count {
                if let city = array[indexPath.row] as? City {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
                    cell.presenter = self
                    cell.configure(with: city)
                    return cell
                } else {
                    return UITableViewCell()
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCityCell", for: indexPath)
                cell.textLabel?.text = "Add city"
                return cell
            }
        }
    }
}
