//
//  CityHelper.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/29/19.
//

import RenderCloud

public protocol CityHelperDelegate: class {
    func didStartCreatingCity()
    func didSelectCity(_ city: City?)
    func didFailSelectCity(with error: Error?)
    func didCancelSelectCity()
}

public class CityHelper: NSObject {
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
    
    weak var inputCity: UITextField? // set by user
    internal var inputState: UITextField?
    internal var cityPickerView: UIPickerView = UIPickerView()
    internal var statePickerView: UIPickerView = UIPickerView()
    var pickerRow: Int = 0
    public var currentCityId: String?
    
    weak var presenter: UIViewController?
    weak var service: CityService?
    weak var delegate: CityHelperDelegate?
    private var cities: [City]? {
        return service?._cities
    }
    
    public convenience init(inputField: UITextField, delegate: CityHelperDelegate?, service: CityService? = CityService.shared) {
        self.init()
        
        inputCity = inputField
        self.service = service
        self.delegate = delegate
        
        // TODO: expose getCities in VenueService on a readWriteQueue
        if service?._cities.isEmpty ?? true {
            service?.getCities { [weak self] (cities) in
                print("loaded \(cities) cities")
                DispatchQueue.main.async { [weak self] in
                    self?.refreshCities()
                }
            }
        }
        
        setupInputs()
    }
    
    public func showCitySelector(from presenter: UIViewController) {
        self.presenter = presenter
    }
    
    private func setupInputs() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEditing))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: .done, target: self, action: #selector(save))
        keyboardDoneButtonView.setItems([cancel, flex, saveButton], animated: true)
        
        self.inputCity?.inputAccessoryView = keyboardDoneButtonView
        for picker in [cityPickerView, statePickerView] {
            picker.sizeToFit()
            picker.delegate = self
            picker.dataSource = self
        }
        inputCity?.inputView = cityPickerView
    }
    
    @objc internal func save() {
        guard let cities = cities, !cities.isEmpty else { return }
        inputCity?.endEditing(true)
        inputState?.endEditing(true)
        if pickerRow > 0 && pickerRow <= cities.count {
            delegate?.didSelectCity(cities[pickerRow - 1])
        } else if pickerRow == 0 {
            print("Add a city")
            promptForNewCity()
        }
    }
    
    @objc internal func cancelEditing() {
        inputCity?.endEditing(true)
        inputState?.endEditing(true)
        
        delegate?.didCancelSelectCity()
    }
    
    internal func promptForNewCity() {
        inputCity?.resignFirstResponder()
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
            self.inputState = textField
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let value = textField.text, !value.isEmpty {
                self.delegate?.didStartCreatingCity()
                self.service?.createCity(city, state: value, lat: 0, lon: 0, completion: { [weak self] (city, error) in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.delegate?.didFailSelectCity(with: error)
                        }
                    } else {
                        // update current city and cities list
                        self?.currentCityId = city?.id
                        self?.service?.getCities(completion: { [weak self] (cities) in
                            DispatchQueue.main.async {
                                self?.refreshCities()
                                self?.delegate?.didSelectCity(city)
                            }
                        })
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
    
    public func refreshCities() {
        cityPickerView.reloadAllComponents()
        if let cityId = currentCityId, let index = cities?.firstIndex(where: { $0.id == cityId }) {
            pickerRow = index + 1
            cityPickerView.selectRow(pickerRow, inComponent: 0, animated: true)
        }
    }
}

extension CityHelper: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == cityPickerView {
            return (cities?.count ?? 0) + 1
        } else if pickerView == statePickerView {
            return stateAbbreviations.count
        }
        return 0
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == cityPickerView {
            guard let cities = cities, !cities.isEmpty else { return "Loading cities..." }
            if row == 0 {
                return "Add a city"
            } else if row <= cities.count  {
                return cities[row - 1].shortString
            }
        } else if pickerView == statePickerView, row < stateAbbreviations.count {
            return stateAbbreviations[row]
        }
        return nil
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == cityPickerView {
            guard let cities = cities, !cities.isEmpty else { return }
            pickerRow = row
            if row > 0 && row <= cities.count {
                let city = cities[row - 1]
                inputCity?.text = city.shortString
                currentCityId = city.id
            }
        } else if pickerView == statePickerView {
            if row < stateAbbreviations.count {
                print("Picked state \(stateAbbreviations[row])")
                inputState?.text = stateAbbreviations[row]
                currentCityId = nil
            }
        }
    }
}
