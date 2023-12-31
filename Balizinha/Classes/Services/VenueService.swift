//
//  VenueService.swift
//  Balizinha
//
//  Created by Bobby Ren on 5/16/19.
//

import RenderCloud

public class VenueService: BaseService {
    // MARK: - Singleton
    public static var shared: VenueService = VenueService()
    
    override var refName: String {
        return "venues"
    }
    
    override func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        return Venue(snapshot: snapshot)
    }

    public func createVenue(userId: String, type: Venue.SpaceType, name: String? = nil, street: String? = nil, city: String? = nil, state: String? = nil, lat: Double? = nil, lon: Double? = nil, placeId: String?, completion:((Venue?, Error?) -> Void)?) {
        // todo: if this is a codable, handle optionals
        var params: [String: Any] = ["userId": userId, "type": type.rawValue]
        if let name = name {
            params["name"] = name
        }
        if let street = street {
            params["street"] = street
        }
        if let city = city {
            params["city"] = city
        }
        if let state = state {
            params["state"] = state
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
                        guard let venue = venue as? Venue else {
                            completion?(nil, nil)
                            return
                        }
                        completion?(venue, nil)
                    })
                } else {
                    completion?(nil, nil)
                }
            }
        }
    }
    
    public func venueForAction(with venueId: String) -> Venue? {
        return cached(venueId) as? Venue
    }

}
