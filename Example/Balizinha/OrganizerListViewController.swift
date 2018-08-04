//
//  OrganizerListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/5/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

class OrganizerListViewController: ListViewController {

    override var refName: String {
        return "organizers"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Organizers"
    }
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel {
        return Organizer(snapshot: snapshot)
    }
    
    override func reloadTable() {
        objects = objects.filter { (model) -> Bool in
            guard let organizer = model as? Organizer else { return false }
            return organizer.status != OrganizerStatus.none
        }
        super.reloadTable()
    }
}

extension OrganizerListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrganizerCell", for: indexPath) as! OrganizerCell
        if indexPath.row < objects.count, let organizer = objects[indexPath.row] as? Organizer {
            cell.configure(organizer: organizer)
        }
        return cell
    }
}

extension OrganizerListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        guard indexPath.row < objects.count else { return }
        
        let organizer = objects[indexPath.row] as? Organizer
    }
}

