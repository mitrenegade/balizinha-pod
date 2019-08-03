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
    var reference: Reference?
    
    override var refName: String {
        return "venues"
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Venues"
        if AIRPLANE_MODE {
            reference = MockDatabaseReference(snapshot: MockDataSnapshot(exists: true, value: ["name": "abc"]))
        } else {
            reference = firRef
        }

        super.viewDidLoad()
    }
}

extension VenuesListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityNameCell", for: indexPath) 
        if indexPath.row < objects.count {
            let venue = objects[indexPath.row] as? Venue
            cell.textLabel?.text = venue?.name ?? ""
            cell.detailTextLabel?.text = venue?.city ?? ""
        }
        return cell
    }
}

extension VenuesListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
