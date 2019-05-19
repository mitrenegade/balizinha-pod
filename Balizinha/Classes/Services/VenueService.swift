//
//  VenueService.swift
//  Balizinha
//
//  Created by Bobby Ren on 5/16/19.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import RenderCloud

public class VenueService: NSObject {
    fileprivate let ref: Reference
    fileprivate let apiService: CloudAPIService
    public init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        ref = reference
        self.apiService = apiService
        super.init()
    }
    
    // MARK: - Singleton
    public static var shared: VenueService = VenueService()
    
    public func getCities(completion: (([City])->Void)?) {
        apiService.cloudFunction(functionName: "getCities", method: "POST", params: nil) { [weak self] (results, error) in
            print("getCities results \(results) error \(error)")
            if error != nil {
                print("Error: \(error as NSError?)")
                completion?([])
            } else if let dict = results as? [String: Any], let objectsDict = dict["results"] as? [String: Any] {
                var results: [City] = []
                for (key, val) in objectsDict {
                    if let dict = val as? [String: Any] {
                        let object = Balizinha.City(key: key, dict: dict)
                        results.append(object)
                    }
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
        apiService.cloudFunction(functionName: "createCity", method: "POST", params: params) { (result, error) in
            if let error = error as NSError? {
                completion(nil, error)
            } else {
                print("CreateCity success with result \(String(describing: result))")
                if let dict = result as? [String: Any], let cityId = dict["cityId"] as? String {
                    self.withId(id: cityId, completion: { (city) in
                        completion(city, nil)
                    })
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    public func deleteCity(_ city: City, completion: @escaping (()->Void)) {
        let params: [String: Any] = ["cityId": city.id]
        apiService.cloudFunction(functionName: "deleteCity", method: "POST", params: params) { (result, error) in
            print("DeleteCity result \(result) error \(error)")
            completion()
        }
    }
    
    public func withId(id: String, completion: @escaping ((City?)->Void)) {
        let reference = ref.child(path: "cities").child(path: id)
        reference.observeValue { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let object = City(snapshot: snapshot)
            completion(object)
            
            reference.removeAllObservers()
        }
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
}
