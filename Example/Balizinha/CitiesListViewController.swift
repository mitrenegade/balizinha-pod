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
    var service: CityService?
    var cities: [City] = []

    var cityNames: [String] = []
    var players: [String: [String]] = [:]
    var expanded: [String: Bool] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        if AIRPLANE_MODE {
            service = MockCityService.shared
        } else {
            service = CityService.shared
        }

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        load()
    }
    
    @IBAction func toggleSelector(_ sender: UIControl) {
        if mode == .selectedCities {
            mode = .cityNames
        } else {
            mode = .selectedCities
        }
        load()
    }

    func load() {
        if mode == .selectedCities {
            showLoadingIndicator()
            service?.getCities(completion: { [weak self] (cities) in
                self?.cities = cities
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.reloadTable()
                }
            })

        } else if mode == .cityNames {
            showLoadingIndicator()
            service?.loadPlayerCityStrings { [weak self] (cities, playersForCity) in
                self?.cityNames = cities
                self?.players = playersForCity
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.reloadTable()
                }
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
}

extension CitiesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if mode == .cityNames {
            return cityNames.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mode == .cityNames {
            guard section < cityNames.count else { return 0 }
            let city = cityNames[section]
            let isExpanded: Bool = expanded[city] ?? false
            if isExpanded {
                return players[city]?.count ?? 0
            }
            return 0
        } else {
            return cities.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard mode == .cityNames, section < cityNames.count else { return nil }
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
        if mode == .cityNames {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CityNameCell", for: indexPath)
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
        } else {
            let array = cities
            if indexPath.row < array.count {
                let city = array[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityCell
                cell.presenter = self
                cell.configure(with: city)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCityCell", for: indexPath)
                cell.textLabel?.text = "Add city"
                return cell
            }
        }
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
        
        if mode == .cityNames {
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
        } else {
            if indexPath.row < cities.count {
                let city = cities[indexPath.row]
                promptForVerification(city)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return mode == .selectedCities
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard mode == .selectedCities else { return }
        showLoadingIndicator()
        if indexPath.row < cities.count {
            let city = cities[indexPath.row]
            service?.deleteCity(city) { [weak self] in
                self?.cities.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self?.hideLoadingIndicator()
                    self?.reloadTable()
                }
            }
        }
    }
}

extension CitiesListViewController {
    private func promptForVerification(_ city: City) {
        let title: String
        let message: String
        if !city.verified {
            title = "Verify city?"
            message = "Is this city correct: \(city.shortString ?? "invalid name") (\(city.latLonString ?? "no location"))"
        } else {
            title = "Remove verification?"
            message = "Do you want to change: \(city.shortString ?? "invalid name") (\(city.latLonString ?? "no location")) to unverified?"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            city.verified = !city.verified
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { (action) in
        })
        present(alert, animated: true, completion: nil)
    }
}

