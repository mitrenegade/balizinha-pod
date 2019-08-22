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
import RenderCloud

class ActionListViewController: ListViewController {

    override var refName: String {
        return "actions"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Actions"
        
        load()
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        let action = Action(snapshot: snapshot)
        return action
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
        guard let action = objects[indexPath.row] as? Action, let eventId = action.eventId else { return }
        print("Retrieving results for action \(action.id) with event \(eventId)")
        EventService().actions(for: nil, eventId: eventId) { (actions) in
            print("done")
        }
    }
}

extension ActionListViewController {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let row = indexPath.row
        guard row < objects.count else { return }
        if let action = objects[row] as? Action {
            ActionService.delete(action: action)
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        }
    }
}
