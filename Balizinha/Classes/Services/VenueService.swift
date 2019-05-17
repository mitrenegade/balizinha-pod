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
}
