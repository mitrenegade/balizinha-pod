//
//  ActionListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha
import FirebaseCore
import FirebaseDatabase

class ActionListViewController: ListViewController {

    override var refName: String {
        return "actions"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Actions"
    }
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel {
        return Action(snapshot: snapshot)
    }
}

extension ActionListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! ActionCell
        if indexPath.row < objects.count {
            if let action = objects[indexPath.row] as? Action {
                cell.configure(action: action)
            }
        }
        return cell
    }
}

extension ActionListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = objects[indexPath.row] as? Action, let eventId = action.event else { return }
        print("Retrieving results for action \(action.id) with event \(eventId)")
        EventService().actions(for: nil, eventId: eventId) { (actions) in
            print("done")
        }
    }
}

