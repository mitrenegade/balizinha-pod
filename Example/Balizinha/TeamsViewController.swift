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
    private let MAX_TEAMS = 12
    var players: [Player] = []
    var playerTeam: [String: Int] = [:]
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Create Teams"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Teams", style: .done, target: self, action: #selector(didClickRandom(_:)))

        simpleAlert("To create teams", message: "Click on players to manually assign them to teams. Click on Random to assign everyone else to teams. Up to 12 teams can be manually assigned. If no captains are selected, the order will be randomized.")
    }
    
    @objc func didClickRandom(_ sender: Any) {
        
    }
    
    // convenience function to list the players in a team
    func teamPlayers(team: Int) -> [Player] {
        return playerTeam.compactMap({ (playerId, playerTeam) -> Player? in
            if team == playerTeam {
                return players.first(where: {$0.id == playerId})
            } else {
                return nil
            }
        })
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
            let team: Int? = playerTeam[player.id]
            cell.configure(player: player, team: team)
        }
        return cell
    }
}

extension TeamsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        guard row < players.count else { return }
        let player = players[row]
        
        if let team = playerTeam[player.id] {
            var newTeam = team + 1
            if newTeam > MAX_TEAMS {
                newTeam = 1
            }
            playerTeam[player.id] = newTeam
        } else {
            playerTeam[player.id] = 1
        }
        
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
}
