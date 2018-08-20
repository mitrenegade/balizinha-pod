//
//  EventsViewController.swift
//  Balizinha_Example
//
//  Created by Ren, Bobby on 8/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Firebase
import Balizinha

class EventsListViewController: ListViewController {
    var currentEvents: [Balizinha.Event] = []
    var pastEvents: [Balizinha.Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Games"
        
        let service = EventService.shared
        service.listenForEventUsers { [weak self] in
            self?.reloadTable()
        }
    }
    
    override func load() {
        let eventRef = firRef.child("events").observe(.value) { [weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                self?.currentEvents.removeAll()
                self?.pastEvents.removeAll()
                
                for dict: DataSnapshot in allObjects {
                    let event = Balizinha.Event(snapshot: dict)
                    if event.isPast {
                        self?.pastEvents.append(event)
                    } else {
                        self?.currentEvents.append(event)
                    }
                }
                self?.pastEvents.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.startTime else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })
                self?.currentEvents.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.startTime else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })
                self?.reloadTable()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPlayers", let controller = segue.destination as? EventPlayersViewController {
            controller.event = sender as? Balizinha.Event
        }
    }
}

extension EventsListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Upcoming events"
        }
        return "Past events"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return currentEvents.count
        }
        return pastEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventCell
        
        let array = indexPath.section == 0 ? currentEvents : pastEvents
        if indexPath.row < array.count {
            let event = array[indexPath.row]
            cell.setup(with: event)
        }
        return cell
    }
}

extension EventsListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        let array = indexPath.section == 0 ? currentEvents : pastEvents
        guard indexPath.row < array.count else { return }

        // go to event attendance list
        let event = array[indexPath.row]
        performSegue(withIdentifier: "toPlayers", sender: event)
    }
}

