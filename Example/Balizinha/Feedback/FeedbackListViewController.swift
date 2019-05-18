//
//  FeedbackViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import FirebaseCore
import FirebaseDatabase

class FeedbackListViewController: ListViewController {
    override var refName: String {
        return "feedback"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Feedback"

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
}

extension FeedbackListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackCell", for: indexPath) as! FeedbackCell
        if indexPath.row < objects.count {
            cell.configure(feedback: objects[indexPath.row])
        }
        return cell
    }
}

extension FeedbackListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < objects.count {
            let feedback = objects[indexPath.row]
            promptForToggle(feedback)
        }
    }
    
    func promptForToggle(_ feedback: FirebaseBaseModel) {
        let status = feedback.dict?["status"] as? String ?? "new"
        let newStatus: String
        if status == "new" {
            newStatus = "read"
        } else {
            newStatus = "new"
        }
        let title = "Update status?"
        let alert = UIAlertController(title: title, message: "Change feedback status to \(newStatus)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (action) in
            // TODO
        }))
        alert.addAction(UIAlertAction(title: "Never mind", style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
    }
}

