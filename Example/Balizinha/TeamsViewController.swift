//
//  TeamsViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 2/6/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class TeamsViewController: UIViewController {
    var players: [Player] = []
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Create Teams"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Teams", style: .done, target: self, action: #selector(didClickRandom(_:)))

        simpleAlert("To create teams", message: "Click on players to manually assign them to teams. Click on Random to assign everyone else to teams. Up to 12 teams can be manually assigned. If no captains are selected, the order will be randomized.")
    }
    
    @objc func didClickRandom(_ sender: Any) {
        
    }
}

extension TeamsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! TeamPlayerCell // using leaguePlayerCell is fine
        cell.reset()
        if indexPath.row < players.count {
            let player = players[indexPath.row]
            cell.configure(player: player, team: 1)
        }
        return cell
    }
}
