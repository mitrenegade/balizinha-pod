//
//  EventPlayersViewController.swift
//  Balizinha_Example
//
//  Created by Ren, Bobby on 8/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class EventPlayersViewController: SearchablePlayersViewController {
    var event: Balizinha.Event?
    
    override var sections: [Section] {
        let string: String
        if event?.isPast ?? false {
            string = "Attended"
        } else {
            string = "Attending"
        }
        return [(string, eventPlayers), ("Other", otherPlayers)]
    }
    
    fileprivate var attendingPlayerIds: [String] = []

    // lists filtered based on search and membership
    fileprivate var eventPlayers: [Player] = []
    fileprivate var otherPlayers: [Player] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Players"
        
        loadFromRef {
            self.loadEventPlayers() {
                self.search(for: nil)
                self.reloadTableData()
            }
        }
    }
    
    func loadEventPlayers(completion: (()->())?) {
        guard let event = event else {
            completion?()
            return
        }
        EventService.shared.observeUsers(for: event) {[weak self] (playerIds) in
            self?.attendingPlayerIds = playerIds
            completion?()
        }
    }
}

extension EventPlayersViewController { // UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LeaguePlayerCell // using leaguePlayerCell is fine
        cell.reset()
        let section = sections[indexPath.section]
        let array = section.players
        if indexPath.row < array.count {
            let playerId = array[indexPath.row].id
            PlayerService.shared.withId(id: playerId) { [weak self] (player) in
                if let player = player {
                    let status: Membership.Status = self?.memberships[player.id] ?? .none
                    DispatchQueue.main.async {
                        cell.configure(player: player, status: status)
                    }
                }
            }
        }
        return cell
        
    }
}

extension EventPlayersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let event = event else { return }
        
        // TODO: what happens when a player is clicked?
        // TODO: clicking allows the organizer to add or remove players?
        let section = sections[indexPath.section]
        guard indexPath.row < section.players.count else { return }
        let playerId: String = section.players[indexPath.row].id
        switch section.name {
        case "Attending", "Attended":
            EventService.shared.leaveEvent(event, userId: playerId, removedByOrganizer: true) { [weak self] (error) in
                if let error = error as NSError? {
                    self?.simpleAlert("Could not remove player", defaultMessage: "The player \(playerId) could not be removed from the event", error: error)
                } else {
                    self?.loadEventPlayers() {
                        self?.search(for: nil)
                        self?.reloadTableData()
                    }
                }
            }
        case "Other":
            EventService.shared.joinEvent(event, userId: playerId, addedByOrganizer: true) { [weak self] (error) in
                if let error = error as NSError? {
                    self?.simpleAlert("Could not add player", defaultMessage: "The player \(playerId) could not be added to the event", error: error)
                } else {
                    self?.loadEventPlayers() {
                        self?.search(for: nil)
                        self?.reloadTableData()
                    }
                }
            }
        default:
            return
        }
        
    }
}

// MARK: - Search
extension EventPlayersViewController {
    @objc override func updateSections(_ players: [Player]) {
        // filter for event attendance
        eventPlayers = players.filter() { return attendingPlayerIds.contains($0.id) }
        otherPlayers = players.filter() { return !attendingPlayerIds.contains($0.id) }
    }
}