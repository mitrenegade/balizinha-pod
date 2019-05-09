//
//  CitiesListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import RenderCloud
import Balizinha

class CitiesListViewController: UIViewController {    
    @IBOutlet weak var tableView: UITableView!
    var cities: [String] = []
    var players: [String: [String]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        load()
    }
    
    func load() {
        let ref: Query
        let refName = "cityPlayers"
        ref = firRef.child(refName).queryOrdered(byChild: "createdAt")
        ref.observeSingleValue() { [weak self] (snapshot) in
            guard snapshot.exists() else { return }
            guard let self = self else { return }
            if let allObjects = snapshot.allChildren {
                for object in allObjects {
                    print("Snapshot key \(object.key) value \(String(describing: object.value))")
                    self.cities.append(object.key)
                    self.players[object.key] = object.value as? [String]
                }
                
                self.cities = self.cities.sorted()
                self.reloadTable()
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
}

extension CitiesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        if indexPath.row < cities.count {
            cell.textLabel?.text = cities[indexPath.row]
        }
        return cell
    }
}

extension CitiesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

