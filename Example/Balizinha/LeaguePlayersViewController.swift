//
//  LeaguePlayersViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/7/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCore
import Balizinha
import FirebaseDatabase

protocol RosterUpdateDelegate: class {
    func didUpdateRoster()
}

class LeaguePlayersViewController: SearchablePlayersViewController {
    var league: League?
    var isEditOrganizerMode: Bool = false
    
    weak var delegate: RosterUpdateDelegate?

    override var sections: [Section] {
        return [("Organizers", organizers), ("Members", members), ("Players", players)]
    }

    // lists filtered based on search and membership
    fileprivate var members: [Player] = [] // all members including organizers
    fileprivate var organizers: [Player] = []
    fileprivate var players: [Player] = [] // non-members
    
    var roster: [Membership]? {
        didSet {
            if let roster = roster {
                for membership in roster {
                    memberships[membership.playerId] = membership.status
                }
            } else {
                memberships.removeAll()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isEditOrganizerMode {
            // only allowed to toggle current organizers
            navigationItem.title = "Edit Organizers"
        } else {
            // only allowed to add/remove players
            navigationItem.title = "Players"
        }
        
        loadFromRef {
            self.search(for: nil)
            self.reloadTableData()
        }
    }
}

extension LeaguePlayersViewController { // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isEditOrganizerMode {
            return 2
        }
        return sections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LeaguePlayerCell
        let status: Membership.Status
        let section = sections[indexPath.section]
        switch section.name {
        case "Organizers":
            status = Membership.Status.organizer
        case "Members":
            status = Membership.Status.member
        case "Players":
            status = Membership.Status.none
        default:
            return cell
        }
        cell.reset()
        let array = section.players
        if indexPath.row < array.count {
            let playerId = array[indexPath.row].id
            PlayerService.shared.withId(id: playerId) { (player) in
                if let player = player {
                    DispatchQueue.main.async {
                        cell.configure(player: player, status: status)
                    }
                }
            }
        }
        return cell
        
    }
}

extension LeaguePlayersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let league = league else { return }
        let newStatus: Membership.Status

        let section = sections[indexPath.section]
        guard indexPath.row < section.players.count else { return }
        let playerId: String = section.players[indexPath.row].id
        switch section.name {
        case "Organizers" :
            newStatus = .member
        case "Members" :
            if isEditOrganizerMode {
                newStatus = .organizer
            } else {
                newStatus = .none
            }
        case "Players":
            newStatus = .member
        default:
            return
        }
       
        // cache old value in case of failure, to revert
        let oldStatus = memberships[playerId]
        
        // update first before web request returns
        memberships[playerId] = newStatus
        search(for: searchTerm)
        
        LeagueService.shared.changeLeaguePlayerStatus(playerId: playerId, league: league, status: newStatus.rawValue, completion: { [weak self] (result, error) in
            print("Result \(String(describing: result)) error \(String(describing: error))")
            if let error = error as NSError? {
                self?.memberships[playerId] = oldStatus
                DispatchQueue.main.async {
                    self?.simpleAlert("Update failed", defaultMessage: "Could not update status to \(newStatus.rawValue). ", error: error)
                }
            }
            DispatchQueue.main.async {
                self?.search(for: self?.searchTerm)
                self?.delegate?.didUpdateRoster()
            }
        })
    }
}

// MARK: - Search
extension LeaguePlayersViewController {
    @objc override func updateSections(_ players: [Player]) {
        // filter for membership
        organizers = players.filter() { return memberships[$0.id] == Membership.Status.organizer }
        members = players.filter() { return memberships[$0.id] == Membership.Status.member }
        self.players = players.filter() { return memberships[$0.id] == nil || memberships[$0.id] == Membership.Status.none }
    }
}
