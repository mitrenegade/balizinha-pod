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

class VenuesListViewController: UIViewController {
    var venues: [Venue] = []
    var cities: [City] = []
    var service: VenueService?
    var reference: Reference?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Venues"
        if AIRPLANE_MODE {
            service = MockVenueService.shared
        } else {
            service = VenueService.shared
        }
        reference = firRef

        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        load()
    }

    func load() {
        showLoadingIndicator()
        service?.getCities(completion: { [weak self] (cities) in
            self?.cities = cities
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                self?.reloadTable()
            }
        })
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
}

extension VenuesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Venues"
        }
        return "Cities"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return cities.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
//            let array = venues
//            if indexPath.row < array.count {
//                let venue = array[indexPath.row]
//                cell.textLabel?.text = venue.name ?? ""
//                cell.detailTextLabel?.text = venue.city ?? ""
//            }
            return UITableViewCell()
        } else {
            let array = cities
            if indexPath.row < array.count {
                let city = array[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
                cell.presenter = self
                cell.configure(with: city)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCityCell", for: indexPath)
                cell.textLabel?.text = "Add city"
                return cell
            }
        }
    }
}

extension VenuesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
}
