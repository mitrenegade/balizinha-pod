//
//  CityHelper.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/29/19.
//

import UIKit
import RenderCloud

protocol CityHelperDelegate: class {
    func didSelectCity(_ city: City?)
}
class CityHelper: NSObject {
    var stateAbbreviations = [ "AK",
                               "AL",
                               "AR",
                               "AS",
                               "AZ",
                               "CA",
                               "CO",
                               "CT",
                               "DC",
                               "DE",
                               "FL",
                               "GA",
                               "GU",
                               "HI",
                               "IA",
                               "ID",
                               "IL",
                               "IN",
                               "KS",
                               "KY",
                               "LA",
                               "MA",
                               "MD",
                               "ME",
                               "MI",
                               "MN",
                               "MO",
                               "MS",
                               "MT",
                               "NC",
                               "ND",
                               "NE",
                               "NH",
                               "NJ",
                               "NM",
                               "NV",
                               "NY",
                               "OH",
                               "OK",
                               "OR",
                               "PA",
                               "PR",
                               "RI",
                               "SC",
                               "SD",
                               "TN",
                               "TX",
                               "UT",
                               "VA",
                               "VI",
                               "VT",
                               "WA",
                               "WI",
                               "WV",
                               "WY"]

    var inputCity: String?
    var inputState: String?
    var cityPickerView: UIPickerView = UIPickerView()
    var statePickerView: UIPickerView = UIPickerView()
    var pickerRow: Int = -1
    var cities: [City] = []

    weak var textField: UITextField?
    weak var presenter: UIViewController?
    weak var service: CityService?
    weak var delegate: CityHelperDelegate?
    
    public convenience init(inputField: UITextField?, delegate: CityHelperDelegate?, service: CityService? = CityService.shared) {
        self.init()
        
        textField = inputField
        self.service = service
        self.delegate = delegate
        
        setupInputs()
    }
    
    public func showCitySelector(from presenter: UIViewController) {
        self.presenter = presenter
        promptForNewCity()
    }

    internal func setupInputs() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEditing))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: .done, target: self, action: #selector(save))
        keyboardDoneButtonView.setItems([cancel, flex, saveButton], animated: true)
        
        self.textField?.inputAccessoryView = keyboardDoneButtonView
        for picker in [cityPickerView, statePickerView] {
            picker.sizeToFit()
            picker.backgroundColor = .white
            picker.delegate = self
            picker.dataSource = self
        }
    }
    
    @objc func save() {
//        self.view.endEditing(true)
        
        if pickerRow > 0 && pickerRow <= cities.count {
            inputCity = cities[pickerRow - 1].name
        } else if pickerRow == 0 {
            print("Add a city")
            promptForNewCity()
        }
    }
    
    @objc func cancelEditing() {
//        self.view.endEditing(true)
    }
    
    internal func promptForNewCity() {
        textField?.resignFirstResponder()
        let alert = UIAlertController(title: "Please enter a city name", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Boston"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let value = textField.text, !value.isEmpty {
                self.promptForNewState(value)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        presenter?.present(alert, animated: true)
    }
    
    internal func promptForNewState(_ city: String) {
        let alert = UIAlertController(title: "Please select the state", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "MA"
            textField.inputView = self.statePickerView
            self.inputState = textField.text
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let value = textField.text, !value.isEmpty {
//                self.showLoadingIndicator()
                self.service?.createCity(city, state: value, lat: 0, lon: 0, completion: { [weak self] (city, error) in
                    DispatchQueue.main.async {
                        self?.delegate?.didSelectCity(city)
////                        self?.hideLoadingIndicator()
//                        if let city = city {
//                            self?.player?.city = city.shortString
//                            self?.player?.cityId = city.firebaseKey
//                            self?.inputCity.text = city.shortString
//                        } else if let error = error {
//                            self?.simpleAlert("Could not create city", defaultMessage: nil, error: error)
//                        }
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        presenter?.present(alert, animated: true)
        
        // force first element in state list to be selected to populate textfield
        statePickerView.selectRow(0, inComponent: 0, animated: true)
        pickerView(statePickerView, didSelectRow: 0, inComponent: 0)
    }
}

extension CityHelper: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == cityPickerView {
            return cities.count + 1
        } else if pickerView == statePickerView {
            return stateAbbreviations.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == cityPickerView {
            if row == 0 {
                return "Add a city"
            } else if row <= cities.count {
                return cities[row - 1].shortString
            }
        } else if pickerView == statePickerView, row < stateAbbreviations.count {
            return stateAbbreviations[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == cityPickerView {
            pickerRow = row
            if row > 0 && row <= cities.count {
                let city = cities[row - 1]
                inputCity = city.shortString
            }
        } else if pickerView == statePickerView {
            if row < stateAbbreviations.count {
                print("Picked state \(stateAbbreviations[row])")
                inputState = stateAbbreviations[row]
            }
        }
    }
}
