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

class VenueService: NSObject {
    fileprivate let ref: Reference
    fileprivate let apiService: CloudAPIService
    public init(reference: Reference = firRef, apiService: CloudAPIService = RenderAPIService()) {
        ref = reference
        self.apiService = apiService
        super.init()
    }
    
    // read write queues
    fileprivate let readWriteQueue = DispatchQueue(label: "venueServiceReadWriteQueue", attributes: .concurrent)
    fileprivate let eventIdQueue = DispatchQueue(label: "venueServiceIdReadWriteQueue", attributes: .concurrent)
    
    // MARK: - Singleton
    public static var shared: VenueService = VenueService()
    public class func resetOnLogout() {
    }
    
    public func getVenues(completion: (([Venue])->Void)?) {
        apiService.cloudFunction(functionName: "getVenues", method: "POST", params: nil) { [weak self] (results, error) in
            if error != nil {
                print("Error: \(error as NSError?)")
                completion?([])
            } else if let dict = results as? [String: Any], let objectsDict = dict["venues"] as? [String: Any] {
                var venues: [Venue] = []
                for (key, val) in objectsDict {
                    if let dict = val as? [String: Any] {
                        let object = Balizinha.Venue(key: key, dict: dict)
                        venues.append(object)
                    }
                }
                completion?(venues)
            }
        }
    }
}
