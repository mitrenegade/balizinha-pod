//
//  StripeMenuViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 1/26/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class StripeMenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension StripeMenuViewController: UITableViewDataSource {
    
}

extension StripeMenuViewController: UITableViewDelegate {
    
}
