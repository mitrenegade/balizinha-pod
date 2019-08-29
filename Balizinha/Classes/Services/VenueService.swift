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

public class VenueService: BaseService {
    fileprivate let baseRef: Reference
    fileprivate let apiService: CloudAPIService
    public init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        baseRef = reference
        self.apiService = apiService
        super.init()
    }
    
    // TODO: readwritequeue
    public var _cities: [City] = []
    
    // MARK: - Singleton
    public static var shared: VenueService = VenueService()
    
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
                    self?.cityWithId(id: cityId, completion: { (city) in
                        completion(city, nil)
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
    
    public func cityWithId(id: String, completion: @escaping ((City?)->Void)) {
        let reference = baseRef.child(path: "cities").child(path: id)
        reference.observeValue { (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let object = City(snapshot: snapshot)
            completion(object)
            
            reference.removeAllObservers()
        }
    }

    public func withId(id: String, completion: @escaping ((Venue?)->Void)) {
        if let found = cached(id) as? Venue {
            completion(found)
            return
        }

        let reference = baseRef.child(path: "venues").child(path: id)
        reference.observeValue { [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            let object = Venue(snapshot: snapshot)
            self?.cache(object)
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
    
    public func createVenue(userId: String, type: Venue.SpaceType, name: String? = nil, street: String? = nil, cityId: String? = nil, lat: Double? = nil, lon: Double? = nil, placeId: String?, completion:((Venue?, Error?) -> Void)?) {
        // todo: if this is a codable, handle optionals
        var params: [String: Any] = ["userId": userId, "type": type.rawValue]
        if let name = name {
            params["name"] = name
        }
        if let street = street {
            params["street"] = street
        }
        if let cityId = cityId {
            params["cityId"] = cityId
        }
        if let lat = lat, let lon = lon {
            params["lat"] = lat
            params["lon"] = lon
        }
        // placeholder for google or apple place
        if let placeId = placeId {
            params["placeId"] = placeId
        }

        // call cloud service
        apiService.cloudFunction(functionName: "createVenue", method: "POST", params: params) { [weak self] (result, error) in
            if let error = error as NSError? {
                completion?(nil, error)
                return
            } else {
                print("CreateVenue success with result \(String(describing: result))")
                if let dict = result as? [String: Any], let venueId = dict["venueId"] as? String{
                    self?.withId(id: venueId, completion: { (venue) in
                        guard let venue = venue else {
                            completion?(nil, nil)
                            return
                        }
                        completion?(venue, nil)
                    })
                    return
                }
            }
            completion?(nil, nil)
        }
    }

}

// notifications
extension VenueService {
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
