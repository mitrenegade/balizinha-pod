//
//  CityService.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/29/19.
//

import UIKit
import RenderCloud

public class CityService: BaseService {
    // MARK: - Singleton
    public static var shared: CityService = CityService()

    // TODO: readwritequeue
    public var _cities: [City] = []
    
    override var refName: String {
        return "cities"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return City(snapshot: snapshot)
    }

    public func getCities(completion: (([City])->Void)?) {
        apiService.cloudFunction(functionName: "getCities", method: "POST", params: nil) { [weak self] (results, error) in
            if error != nil {
                completion?([])
            } else if let dict = results as? [String: Any], let objectsDict = dict["results"] as? [String: Any] {
                var results: [City] = []
                for (key, val) in objectsDict {
                    if let dict = val as? [String: Any] {
                        let object = Balizinha.City(key: key, dict: dict)
                        results.append(object)
                    }
                }
                results = results.sorted(by: { (c1, c2) -> Bool in
                    guard let n1 = c1.name else { return false }
                    guard let n2 = c2.name else { return true }
                    return n1 < n2
                })
                
                self?.readWriteQueue2.async(flags: .barrier) { [weak self] in
                    self?._cities = results
                }
                completion?(results)
            }
        }
    }
    
    public func createCity(_ name: String, state: String?, lat: Double?, lon: Double?, completion:@escaping (City?, NSError?) -> Void) {
        
        var params: [String: Any] = ["name": name]
        if let state = state {
            params["state"] = state
        }
        if let lat = lat, let lon = lon {
            params["lat"] = lat
            params["lon"] = lon
        }
        apiService.cloudFunction(functionName: "createCity", method: "POST", params: params) { [weak self] (result, error) in
            if let error = error as NSError? {
                completion(nil, error)
            } else {
                print("CreateCity success with result \(String(describing: result))")
                if let dict = result as? [String: Any], let cityId = dict["cityId"] as? String {
                    self?.withId(id: cityId, completion: { (city) in
                        completion(city as? City, nil)
                    })
                    return
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    public func deleteCity(_ city: City, completion: @escaping (()->Void)) {
        let params: [String: Any] = ["cityId": city.id]
        apiService.cloudFunction(functionName: "deleteCity", method: "POST", params: params) { (result, error) in
            completion()
        }
    }
    
    public func cityFromName(_ name: String, state: String) -> City? {
        return _cities.filter { name.lowercased() == $0.name?.lowercased() && state.lowercased() == $0.state?.lowercased() }.first
    }

    // For Admin only
    public func loadPlayerCityStrings(includeInvalidCities: Bool = true, completion: @escaping ([String], [String: [String]])->Void) {
        let ref: Query
        let refName = "cityPlayers"
        ref = firRef.child(refName).queryOrdered(byChild: "createdAt")
        ref.observeSingleValue() { (snapshot) in
            guard snapshot.exists() else {
                completion([], [:])
                return
            }
            if let allObjects = snapshot.allChildren {
                var cities: [String] = []
                var playersForCity: [String: [String]] = [:]
                var notCities: [String] = []
                for object in allObjects {
                    print("Snapshot key \(object.key) value \(String(describing: object.value))")
                    if let playerStatus = object.value as? [String: Bool] {
                        let allPlayers = playerStatus.compactMap({ (key, val) -> String? in
                            if val {
                                return key
                            }
                            return nil
                        })
                        if !allPlayers.isEmpty {
                            cities.append(object.key)
                            playersForCity[object.key] = allPlayers
                        }
                    } else if let playerActive = object.value as? Bool {
                        if playerActive {
                            notCities.append(object.key)
                            playersForCity[object.key] = [object.key]
                        }
                    }
                }
                
                cities = cities.sorted()
                if includeInvalidCities {
                    cities.append(contentsOf: notCities.sorted())
                }
                completion(cities, playersForCity)
            }
        }
    }
    
    public func isCityLocationValid(city: City?) -> Bool {
        guard let city = city, let lat = city.lat, let lon = city.lon else { return false }
        guard lat != 0 && lon != 0 else { return false }
        return city.verified == true
    }
}

// notifications
extension CityService {
    public func checkForUnverifiedCity(completion: @escaping ((Bool) -> Void)) {
        let ref: Reference
        ref = baseRef.child(path: "cities")
        ref.observeSingleValue() {(snapshot) in
            guard snapshot.exists() else { completion(false); return }
            if let allObjects = snapshot.allChildren {
                for dict: Snapshot in allObjects {
                    let city = City(snapshot: dict)
                    if !city.verified {
                        completion(true)
                        return
                    }
                }
            }
            completion(false)
        }
    }
    
}
