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
import RenderCloud

enum UtilItem: String, CaseIterable {
    case updateEventLeagueIsPrivate
    case recountLeagueStats
    case migrateEventImages
    case cleanupAnonymousAuth
    case refreshAllPlayerTopics

    var details: String {
        switch self {
        case .updateEventLeagueIsPrivate:
            return "Updates all event's leagueIsPrivate parameter"
        case .recountLeagueStats:
            return "Regenerates league player and event counts"
        case .migrateEventImages:
            return "Ensures event images are stored under the event id"
        case .cleanupAnonymousAuth:
            return "Removes old anonymous auth users"
        case .refreshAllPlayerTopics:
            return "Enables notifications for leagues and events for a player"
            
        }
    }
}

class UtilsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate let activityOverlay: ActivityIndicatorOverlay = ActivityIndicatorOverlay()

    var menuItems: [UtilItem] = UtilItem.allCases

    // player selection
    let inputPlayerSelector: UITextField = UITextField()
    var pickerView: UIPickerView = UIPickerView()
    var players: [Player] = []
    var selectingPlayerId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Utils"
        activityOverlay.setup(frame: view.frame)
        tableView.addSubview(activityOverlay)
        
        pickerView.sizeToFit()
        pickerView.backgroundColor = .white
        pickerView.delegate = self
        pickerView.dataSource = self
        inputPlayerSelector.inputView = pickerView
        
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let next: UIBarButtonItem = UIBarButtonItem(title: "Go", style: UIBarButtonItemStyle.done, target: self, action: #selector(selectPlayer))
        keyboardNextButtonView.setItems([flex, cancel, next], animated: true)
        
        inputPlayerSelector.inputAccessoryView = keyboardNextButtonView

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
        case .cleanupAnonymousAuth:
            cleanupAnonymousAuth()
        case .refreshAllPlayerTopics:
            refreshAllPlayerTopics()
        default:
            activityOverlay.show()
            FirebaseAPIService().cloudFunction(functionName: selection.rawValue, method: "POST", params: nil) { [weak self] (result, error) in
                DispatchQueue.main.async {
                    self?.activityOverlay.hide()
                }
                if let error = error {
                    print("Error: \(error)")
                } else {
                    print("Result: \(String(describing: result)))")
                }
            }
        }
    }
}

extension UtilsViewController {
    func cleanupAnonymousAuth() {
        activityOverlay.show()
        FirebaseAPIService().cloudFunction(functionName: "cleanupAnonymousAuth", method: "POST", params: nil) { [weak self] (result, error) in
            DispatchQueue.main.async {
                self?.activityOverlay.hide()
            }
            if let error = error {
                print("Error: \(error)")
            } else if let users = result as? [String: Any] {
                // result should be ["uid": ["exists": true or "deleted": true/false]]
                // function returns {result: [ ]}
                print("Result: \(users)")
                let userCount = users.count
                let players = users.filter() { $0.value as? String == "exists" }
                let deletedUsers = users.filter() { return ($0.value as? [String: Any] ?? [:])["deleted"] as? Bool == true }

                let deletedCount = deletedUsers.count
                let playerCount = players.count
                print("Total users \(userCount) players \(playerCount) deleted \(deletedCount)")
            }
        }
    }
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
            var photoIdFailed: Int = 0
            var photoUrlFailed: Int = 0
            let dispatchGroup = DispatchGroup()
            for childSnapshot: DataSnapshot in allObjects {
                let event = Balizinha.Event(snapshot: childSnapshot)
                dispatchGroup.enter()
                if let photoId = event.dict["photoId"] as? String {
                    print("---> Event \(event.id) has photoId \(photoId)")
                    guard photoId != event.id else {
                        alreadyConvertedCount += 1
                        dispatchGroup.leave()
                        // DONE: delete photoId
                        event.firebaseRef?.child("photoId").removeValue()
                        continue
                    }
                    FirebaseImageService().eventPhotoUrl(for: event, completion: { (url) in
                        if let url = url {
                            // if the url already exists, count this as already converted
                            alreadyConvertedCount += 1
                            dispatchGroup.leave()
                            print("Event \(event.id) has valid url \(url.absoluteString)")

                            // DONE: delete photoId
                            event.firebaseRef?.child("photoId").removeValue()
                        } else {
                            FirebaseImageService().eventPhotoUrl(with: photoId, completion: { (url) in
                                if let urlString = url?.absoluteString {
                                    // DONE: download the image and store it
                                    let manager = RAImageManager(imageView: nil)
                                    manager.load(imageUrl: urlString, completion: { [weak self] (image) in
                                        if let image = image {
                                            DispatchQueue.main.async {
                                                FirebaseImageService.uploadImage(image: image, type: .event, uid: event.id, completion: { (url) in
                                                    print("Event \(event.id) has photoId url \(urlString), converted")
                                                    photoIdCount += 1
                                                    dispatchGroup.leave()
                                                    // DONE: delete photoId
                                                    event.firebaseRef?.child("photoId").removeValue()
                                                })
                                            }
                                        } else {
                                            print("Event \(event.id) has photoId url \(urlString), was invalid")
                                            photoIdFailed += 1
                                            dispatchGroup.leave()
                                            // DONE: delete photoId
                                            event.firebaseRef?.child("photoId").removeValue()
                                        }
                                    })
                                } else {
                                    print("Event \(event.id) does not have a valid photoId url")
                                    photoIdFailed += 1
                                    dispatchGroup.leave()
                                    // DONE: delete photoId
                                    event.firebaseRef?.child("photoId").removeValue()
                                }
                            })
                        }
                    })
                } else if let photoUrl = event.dict["photoUrl"] as? String {
                    FirebaseImageService().eventPhotoUrl(for: event, completion: { (url) in
                        if let url = url {
                            // if the url already exists, count this as already converted
                            alreadyConvertedCount += 1
                            dispatchGroup.leave()
                            print("Event \(event.id) has valid url \(url.absoluteString)")
                            
                            // DONE: delete photoUrl
                            event.firebaseRef?.child("photoUrl").removeValue()
                        } else {
                            // DONE: download the image and store it
                            let manager = RAImageManager(imageView: nil)
                            manager.load(imageUrl: photoUrl, completion: { [weak self] (image) in
                                if let image = image {
                                    DispatchQueue.main.async {
                                        FirebaseImageService.uploadImage(image: image, type: .event, uid: event.id, completion: { (url) in
                                            print("Event \(event.id) has photoUrl \(photoUrl), converted")
                                            photoUrlCount += 1
                                            dispatchGroup.leave()
                                            // DONE: delete photoUrl
                                            event.firebaseRef?.child("photoUrl").removeValue()
                                        })
                                    }
                                } else {
                                    print("Event \(event.id) has photoUrl \(photoUrl), was invalid")
                                    photoUrlFailed += 1
                                    dispatchGroup.leave()
                                    // DONE: delete photoId
                                    event.firebaseRef?.child("photoUrl").removeValue()
                                }
                            })
                        }
                    })
                } else {
                    FirebaseImageService().eventPhotoUrl(for: event, completion: { (url) in
                        if let url = url {
                            alreadyConvertedCount += 1
                            dispatchGroup.leave()
                            print("Event \(event.id) has valid url \(url.absoluteString)")
                        } else {
                            noPhotoUrlCount += 1
                            dispatchGroup.leave()
                        }
                    })
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
                print("migrateEventUrls: photoUrl \(photoUrlCount) photoUrlFailed \(photoUrlFailed) photoId \(photoIdCount) photoIdFailed \(photoIdFailed) alreadyConverted \(alreadyConvertedCount) noPhotoUrl \(noPhotoUrlCount)")
            }
        }
    }
}

// refresh player topics
extension UtilsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func refreshAllPlayerTopics() {
        view.addSubview(inputPlayerSelector)
        activityOverlay.show()
        let playerRef = firRef.child("players").queryOrdered(byChild: "createdAt")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                self?.players.removeAll()
                for playerDict: DataSnapshot in allObjects {
                    let player = Player(snapshot: playerDict)
                    self?.players.append((player))
                }
                self?.players.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.name else { return false }
                    guard let t2 = p2.name else { return true}
                    if p1.id == "48PJmg3CsXWPKaQUUf496Pt1Xjh1" { return true }
                    if p2.id == "48PJmg3CsXWPKaQUUf496Pt1Xjh1" { return false }
                    return t1 > t2
                })
                self?.activityOverlay.hide()
                self?.inputPlayerSelector.becomeFirstResponder()
                self?.selectingPlayerId = self?.players[0].id
            }
        }
    }

    @objc func cancelInput() {
        selectingPlayerId = nil
        view.endEditing(true)
        inputPlayerSelector.removeFromSuperview()
    }
    
    @objc func selectPlayer() {
        view.endEditing(true)
        inputPlayerSelector.removeFromSuperview()
        guard let userId = selectingPlayerId else {
            simpleAlert("No player selected", message: nil)
            return
        }
        print("RefreshAllPlayerTopics for userId \(userId)")
        let params: [String: Any] = ["userId": userId, "pushEnabled": true]
        activityOverlay.show()
        FirebaseAPIService().cloudFunction(functionName: "refreshAllPlayerTopics", method: "POST", params: params) { [weak self] (result, error) in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self?.simpleAlert("RefreshAllPlayerTopics failed", defaultMessage: "There was an error creating topics for player \(userId)", error: error)
                }
            } else {
                FirebaseAPIService().cloudFunction(functionName: "refreshPlayerSubscriptions", params: params) { [weak self] (result, error) in
                    print("Result \(String(describing: result)) error \(String(describing: error))")
                    DispatchQueue.main.async {
                        if let error = error as NSError? {
                            self?.simpleAlert("RefreshPlayerSubscriptions failed", defaultMessage: "There was an error creating topics for player \(userId)", error: error)
                        } else {
                            var subscribed: Int = -1
                            var unsubscribed: Int = -1
                            if let dict = result as? [String: Any] {
                                if let sub = dict["subscribed"] as? Int {
                                    subscribed = sub
                                }
                                if let unsub = dict["unsubscribed"] as? Int {
                                    unsubscribed = unsub
                                }
                            }
                            self?.simpleAlert("RefreshSubscriptions complete", message: "Subscribed \(subscribed) unsubscribed \(unsubscribed)")
                            self?.activityOverlay.hide()
                        }
                    }
                }
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return players.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let index = row
        guard index < players.count else { return nil }
        return "\(players[index].name ?? "Anon") \(players[index].id)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let index = row
        guard index < players.count else { return }
        selectingPlayerId = players[index].id
    }
}
