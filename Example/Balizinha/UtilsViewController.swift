//
//  UtilsViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/12/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

enum UtilItem: String, CaseIterable {
    case updateEventLeagueIsPrivate = "updateEventLeagueIsPrivate"
    case recountLeagueStats = "recountLeagueStats"

    var details: String {
        switch self {
        case .updateEventLeagueIsPrivate:
            return "Updates all event's leagueIsPrivate parameter"
        case .recountLeagueStats:
            return "Regenerates league player and event counts"
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
//        switch selection {
//        case .updateEventLeagueIsPrivate:
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
//        case .recountLeagueStats:
//            activityOverlay.show()
//        }
    }
}
