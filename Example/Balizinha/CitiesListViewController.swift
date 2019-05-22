//
//  CitiesListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import RenderCloud
import Balizinha

class CitiesListViewController: UIViewController {
    enum Mode: String {
        case cityNames
        case selectedCities
    }
    @IBOutlet weak var selectorMode: UISegmentedControl!
    var mode: Mode = .selectedCities

    @IBOutlet weak var tableView: UITableView!
    var cities: [City] = []

    var cityNames: [String] = []
    var players: [String: [String]] = [:]
    var expanded: [String: Bool] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        load()
    }
    
    @IBAction func toggleSelector(_ sender: UIControl) {
    }

    func load() {
        VenueService.shared.loadPlayerCityStrings { [weak self] (cities, playersForCity) in
            self?.cityNames = cities
            self?.players = playersForCity
            self?.reloadTable()
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
}

extension CitiesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < cityNames.count else { return 0 }
        let city = cityNames[section]
        let isExpanded: Bool = expanded[city] ?? false
        if isExpanded {
            return players[city]?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < cityNames.count else { return nil }
        let city = cityNames[section]
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        view.backgroundColor = UIColor.lightGray

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 39))
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.darkGray
        label.text = city
        label.textAlignment = .center
        view.addSubview(label)

        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40)
        button.addTarget(self, action: #selector(didClickHeader(_:)), for: .touchUpInside)
        button.tag = section
        view.addSubview(button)
        view.clipsToBounds = true
        
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        guard indexPath.section < cityNames.count else {
            return cell
        }
        let city = cityNames[indexPath.section]
        let allPlayers = players[city] ?? []
        let isExpanded: Bool = expanded[city] ?? false
        if !isExpanded {
            return cell
        }
        
        if indexPath.row < allPlayers.count {
            let playerId = allPlayers[indexPath.row]
            PlayerService.shared.withId(id: playerId) { (player) in
                cell.textLabel?.text = player?.name ?? player?.email ?? playerId
            }
        } else {
            cell.textLabel?.text = nil
        }
        return cell
    }
    
    @objc func didClickHeader(_ sender: UIButton) {
        let section = sender.tag
        guard section < cityNames.count else { return }
        let city = cityNames[section]
        expanded[city] = !(expanded[city] ?? false)
        
        self.reloadTable()
    }
}

extension CitiesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let controller = UIStoryboard(name: "Players", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        guard indexPath.section < cityNames.count else {
            return
        }
        let city = cityNames[indexPath.section]
        let allPlayers = players[city] ?? []
        if indexPath.row < allPlayers.count {
            let playerId = allPlayers[indexPath.row]
            PlayerService.shared.withId(id: playerId) { [weak self] (player) in
                controller.player = player
                DispatchQueue.main.async {
                    self?.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
}

