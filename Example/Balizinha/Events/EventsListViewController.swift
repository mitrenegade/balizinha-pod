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
import RenderCloud

class EventsListViewController: ListViewController {
    var currentEvents: [Balizinha.Event] = []
    var pastEvents: [Balizinha.Event] = []
    var service: EventService?
    var reference: Reference?

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Games"
        
        if AIRPLANE_MODE {
            let eventDict: [String: Any] = ["name": "Test event",
                                            "status": "active",
                                            "startTime": (Date().timeIntervalSince1970 + Double(Int(arc4random_uniform(72)) * 3600))]
            let referenceSnapshot = MockDataSnapshot(exists: true,
                                                     key: "1",
                                                     value: eventDict,
                                                     ref: nil)
            reference = MockDatabaseReference(snapshot: referenceSnapshot)
            let apiService = MockCloudAPIService(uniqueId: "abc", results: ["success": true])
            service = EventService(apiService: apiService)
        } else {
            service = EventService.shared
            reference = firRef
        }
        
        super.viewDidLoad()
        
        service?.listenForEventUsers { [weak self] in
            self?.load { [weak self] in
                self?.reloadTable()
            }
        }
    }
    
    override func load(completion: (()->Void)?) {
        // don't use EventService.getAvailableEvents because admin app doesn't filter by user
        activityOverlay.show()
        reference?.child(path: "events").observeValue { [weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects = snapshot.allChildren {
                self?.currentEvents.removeAll()
                self?.pastEvents.removeAll()
                
                for dict: Snapshot in allObjects {
                    let event = Balizinha.Event(snapshot: dict)
                    if event.isPast {
                        self?.pastEvents.append(event)
                    } else {
                        self?.currentEvents.append(event)
                    }
//                    self?.service?.cache(event)
                }
                self?.pastEvents.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.startTime else { return false }
                    guard let t2 = p2.startTime else { return true}
                    return t1 > t2
                })
                self?.currentEvents.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.startTime else { return false }
                    guard let t2 = p2.startTime else { return true}
                    return t1 < t2
                })
                self?.activityOverlay.hide()
                self?.reloadTable()
                completion?()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPlayers", let controller = segue.destination as? EventPlayersViewController {
            controller.event = sender as? Balizinha.Event
        }
    }
    
    private func doCancelEvent(event: Balizinha.Event) {
        service?.cancelEvent(event, isCancelled: !event.isCancelled, completion: { [weak self] (error) in
            let isCancelled = !event.isCancelled
            if let error = error as NSError? {
                let title = "Could not " + (isCancelled ? "cancel" : "reinstate") + " event"
                self?.simpleAlert(title, defaultMessage: "There was an error updating the event's cancellation status. ", error: error)
            } else {
                self?.load() {}
            }
        })
    }
    
    private func doDeleteEvent(_ event: Balizinha.Event) {
        let title = "Are you sure?"
        let alert = UIAlertController(title: title, message: "Deleting event \(event.name ?? event.id) cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm delete", style: .default, handler: { [weak self] (action) in
            self?.service?.deleteEvent(event) { [weak self] (error) in
                if let error = error as NSError? {
                    print("Event \(event.id) delete with error \(error)")
                    let title = "Could not delete event"
                    self?.simpleAlert(title, defaultMessage: "There was an error with deletion.", error: error)
                } else {
                    self?.load() {}
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Never mind", style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
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
        if event.isPast {
            performSegue(withIdentifier: "toPlayers", sender: event)
        } else {
            let title = "Event: \(event.id)"
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "View players", style: .default, handler: { (action) in
                self.performSegue(withIdentifier: "toPlayers", sender: event)
            }))
            let cancelText: String = event.isCancelled ? "Uncancel event" : "Cancel event"
            alert.addAction(UIAlertAction(title: cancelText, style: .default) { [weak self] (action) in
                self?.doCancelEvent(event: event)
            })
            alert.addAction(UIAlertAction(title: "Delete event", style: .default) { [weak self] (action) in
                self?.doDeleteEvent(event)
            })
            alert.addAction(UIAlertAction(title: "Never mind", style: .cancel) { (action) in
            })
            present(alert, animated: true, completion: nil)
        }
    }
}
