//
//  VenuesListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/16/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Firebase
import Balizinha
import RenderCloud

class VenuesListViewController: SearchableListViewController {
    var reference: Reference?
    var venues: [Venue] = []
    let inputField: UITextField = UITextField()
    var cityHelper: CityHelper?
    var selectedCity: City?
//    var cities: [City] = []
    
    override var refName: String {
        return "venues"
    }
    
    override var sections: [Section] {
        return [("Venues", venues)]
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Venue(snapshot: snapshot)
    }

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        navigationItem.title = "Venues"
        if AIRPLANE_MODE {
            reference = MockDatabaseReference(snapshot: MockDataSnapshot(exists: true, value: ["name": "abc"]))
        } else {
            reference = firRef
        }

        super.viewDidLoad()
        
        activityOverlay.show()
        load() { [weak self] in
//            self?.cities = cities
            self?.search(for: nil)
            self?.activityOverlay.hide()
//            CityService.shared.getCities(completion: { [weak self] (cities) in
//            })
        }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createVenue))
    }
    
    @objc func createVenue() {
//        cityHelper = CityHelper(inputField: inputField, delegate: self)
//        cityHelper?.showCitySelector(from: self)
//        cityHelper?.cities = cities
//        inputField.becomeFirstResponder()
        performSegue(withIdentifier: "toLocationSearch", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationSearch", let controller = segue.destination as? PlaceSearchViewController {
            controller.delegate = self
            if let venue = sender as? Venue {
                controller.currentVenue = venue
            }
        }
    }
}

extension VenuesListViewController: CityHelperDelegate {
    func didCancelSelectCity() {
        // TODO
    }
    
    func didStartCreatingCity() {
        self.showLoadingIndicator()
    }
    func didSelectCity(_ city: City?) {
        self.hideLoadingIndicator()
        selectedCity = city
        performSegue(withIdentifier: "toLocationSearch", sender: city)
    }
    
    func didFailSelectCity(with error: Error?) {
        self.hideLoadingIndicator()
        simpleAlert("Could not select city", defaultMessage: "encountered error", error: error as NSError?)
    }
}

// MARK: - TableView Datasource and Delegate
extension VenuesListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as? CityCell else { return UITableViewCell() }
        if indexPath.row < venues.count {
            let venue = venues[indexPath.row]
            cell.configureVenue(with: venue)
            cell.detailTextLabel?.text = venue.city ?? ""
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row < venues.count else { return }
        let venue = venues[indexPath.row]
        performSegue(withIdentifier: "toLocationSearch", sender: venue)
    }
}

// search and filtering
extension VenuesListViewController {
    @objc override func updateSections(_ newObjects: [FirebaseBaseModel]) {
        venues = newObjects.compactMap { $0 as? Venue }
        // TODO: filter by distance
        venues.sort(by: { (p1, p2) -> Bool in
            guard let t1 = p1.createdAt else { return false }
            guard let t2 = p2.createdAt else { return true}
            return t1 > t2
        })
    }
    
    override func doFilter(_ currentSearch: String) -> [FirebaseBaseModel] {
        return objects.filter {(_ object: FirebaseBaseModel) in
            guard currentSearch.count > 2 else { return false } // only match 3 characters or more
            guard let venue = object as? Venue else { return false }
            let nameMatch = venue.name?.lowercased().contains(currentSearch) ?? false
            let idMatch = venue.id.lowercased().contains(currentSearch)
            let streetMatch = venue.street?.lowercased().contains(currentSearch) ?? false
            let cityStateMatch = venue.shortString.lowercased().contains(currentSearch) ?? false
            return nameMatch || idMatch || streetMatch || cityStateMatch
        }
    }
}

// MARK: PlaceSearchDelegate
extension VenuesListViewController: PlaceSelectDelegate {
    func didSelect(venue: Venue?) {
        activityOverlay.show()
        load() { [weak self] in
            self?.search(for: nil)
            self?.activityOverlay.hide()
        }
        navigationController?.popToViewController(self, animated: true)
    }
}
