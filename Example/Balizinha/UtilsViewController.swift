//
//  UtilsViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/12/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import Firebase

enum UtilItem: String, CaseIterable {
    case updateEventLeagueIsPrivate = "updateEventLeagueIsPrivate"
    case recountLeagueStats = "recountLeagueStats"
    case migrateEventImages = "migrateEventImages"

    var details: String {
        switch self {
        case .updateEventLeagueIsPrivate:
            return "Updates all event's leagueIsPrivate parameter"
        case .recountLeagueStats:
            return "Regenerates league player and event counts"
        case .migrateEventImages:
            return "Ensures event images are stored under the event id"
        }
    }
}
class UtilsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    var menuItems: [UtilItem] = UtilItem.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Utils"
        activityOverlay.setup(frame: view.frame)
        view.addSubview(activityOverlay)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        activityOverlay.setup(frame: view.frame)
    }
}

extension UtilsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UtilCell", for: indexPath)
        if indexPath.row < menuItems.count {
            cell.textLabel?.text = menuItems[indexPath.row].rawValue
            cell.detailTextLabel?.text = menuItems[indexPath.row].details
        } else {
            cell.textLabel?.text = nil
        }
        return cell
    }
}

extension UtilsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < menuItems.count else { return }
        let selection = menuItems[indexPath.row]
        switch selection {
        case .migrateEventImages:
            migrateEventImages()
        default:
            activityOverlay.show()
            FirebaseAPIService().cloudFunction(functionName: selection.rawValue, method: "POST", params: nil) { [weak self] (result, error) in
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                }
                if let error = error {
                    print("Error: \(error)")
                } else {
                    print("Result: \(String(describing: result))")
                }
            }
        }
    }
}

extension UtilsViewController {
    func migrateEventImages() {
        // handles event urls locally because firebase image functions exist
        let eventRef = firRef.child("events")
        eventRef.observeSingleEvent(of: .value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
            var photoUrlCount: Int = 0
            var photoIdCount: Int = 0
            var alreadyConvertedCount: Int = 0
            var noPhotoUrlCount: Int = 0
            for childSnapshot: DataSnapshot in allObjects {
                let event = Balizinha.Event(snapshot: childSnapshot)
                guard event.dict["alreadyConverted"] == nil else {
                    alreadyConvertedCount += 1
                    // TODO: delete photoUrl and photoId when new app is out
                    continue
                }
                if let photoId = event.dict["photoId"] {
                    FirebaseImageService().eventPhotoUrl(for: event, completion: { (url) in
                        if let url = url {
                            // if the url already exists, count this as already converted
                            alreadyConvertedCount += 1
                            
                            // TODO: download the image and make sure it works
                        } else {
                            photoIdCount += 1
                            // TODO: download the image and store it
                        }
                        print("migrateEventUrls: photoUrl \(photoUrlCount) photoId \(photoIdCount) alreadyConverted \(alreadyConvertedCount) noPhotoUrl \(noPhotoUrlCount)")
                    })
                } else if let photoUrl = event.dict["photoUrl"] {
                    FirebaseImageService().eventPhotoUrl(for: event, completion: { (url) in
                        if let url = url {
                            // if the url already exists, count this as already converted
                            alreadyConvertedCount += 1
                            
                            // TODO: download the image and make sure it works
                        } else {
                            photoUrlCount += 1
                            // TODO: download the image and store it
                        }
                        print("migrateEventUrls: photoUrl \(photoUrlCount) photoId \(photoIdCount) alreadyConverted \(alreadyConvertedCount) noPhotoUrl \(noPhotoUrlCount)")
                    })
                } else {
                    noPhotoUrlCount += 1
                }
            }
        }
    }
}
