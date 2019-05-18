//
//  CityCell.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class CityCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var latlonLabel: UILabel!
    
    @IBOutlet weak var buttonName: UIButton!
    @IBOutlet weak var buttonState: UIButton!
    @IBOutlet weak var buttonLatLon: UIButton!
    var buttonLon = UIButton() // not displayed
    
    var city: City!
    weak var presenter: UIViewController?
    
    func configure(with city: City?) {
        guard let city = city else { return }
        nameLabel.text = city.name
        stateLabel.text = city.state
        latlonLabel.text = "\(city.lat ?? 0), \(city.lon ?? 0)"
        self.city = city
    }
    
    @IBAction func didTapLabel(_ sender: UIButton?) {
        let title: String
        let value: String?
        let handler: ((String)->Void)
        switch sender {
        case buttonName:
            title = "Update city name"
            value = city.name
            handler = { [weak self] value in
                print("Updated city \(value)")
                self?.city.name = value
                self?.configure(with: self?.city)
            }
        case buttonState:
            title = "Update state"
            value = city.state
            handler = { [weak self] value in
                print("Updated state \(value)")
                self?.city.state = value
                self?.configure(with: self?.city)
            }
        case buttonLatLon:
            title = "Update lat"
            value = "\(city.lat ?? 0)"
            handler = { [weak self] value in
                print("Updated latitude \(value)")
                if let lat = Double(value) {
                    self?.city.lat = lat
                    self?.didTapLabel(self?.buttonLon)
                    self?.configure(with: self?.city)
                }
            }
        case buttonLon:
            title = "Update longitude"
            value = "\(city.lon ?? 0)"
            handler = { [weak self] value in
                print("Updated lon \(value)")
                if let lon = Double(value) {
                    self?.city.lon = lon
                    self?.configure(with: self?.city)
                }
            }
        default:
            return
        }
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.text = value
            textField.placeholder = title
        }
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let newValue = textField.text, !newValue.isEmpty {
                handler(newValue)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        presenter?.present(alert, animated: true)
    }
}
