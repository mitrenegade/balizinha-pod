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
    }
}

