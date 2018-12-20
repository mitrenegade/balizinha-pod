//
//  PaymentService.swift
//  Balizinha
//
//  Created by Bobby Ren on 12/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseDatabase

fileprivate var _stripeCustomers: [String: String] = [:]

public class PaymentService: NSObject {
    public static let shared: PaymentService = PaymentService()
    public override init() {
        super.init()
        getStripeCustomers(completion: nil)
    }

    public func checkForPayment(for eventId: String, by playerId: String, completion:@escaping ((Bool)->Void)) {
        let ref = firRef.child("charges/events/\(eventId)")
        print("checking for payment on \(ref)")
        ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            guard snapshot.exists(), let payments = snapshot.value as? [String: [String: Any]] else {
                completion(false)
                return
            }
            for (_, info) in payments {
                if let player_id = info["player_id"] as? String, playerId == player_id, let status = info["status"] as? String, status == "succeeded", let refund = info["refunded"] as? Double, refund == 0 {
                    completion(true)
                    return
                }
            }
            completion(false)
        }
    }
    
    public func savePaymentInfo(_ source: String, last4: String, label: String) {
        guard let player = PlayerService.shared.current.value else { return }

        let params: [String: Any] = ["userId": player.id, "source": source, "last4": last4, "label": label]
        FirebaseAPIService().cloudFunction(functionName: "savePaymentInfo", method: "POST", params: params) { (result, error) in
            print("FirebaseAPIService: savePaymentInfo result \(result) error \(error)")
        }
    }
    
    public func holdPayment(userId: String, eventId: String, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        let params = ["userId": userId, "eventId": eventId]
        FirebaseAPIService().cloudFunction(functionName: "holdPayment", method: "POST", params: params) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func capturePayment(userId: String, eventId: String, chargeId: String, params: [String: Any]? = nil, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        var info: [String: Any]?
        if let params = params {
            // this allows any params sent in for admin purposes to be included
            info = params
            info?["userId"] = userId
            info?["chargeId"] = chargeId
            info?["eventId"] = eventId
        } else {
            info = ["userId": userId, "eventId": eventId, "chargeId": chargeId]
        }
        FirebaseAPIService().cloudFunction(functionName: "capturePayment", method: "POST", params: info) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func refundPayment(eventId: String, chargeId: String, params: [String: Any]? = nil, completion: ((_ response: Any?, _ error: Error?) -> ())?) {
        var info: [String: Any]?
        if let params = params {
            // this allows any params sent in for admin purposes to be included
            info = params
            info?["chargeId"] = chargeId
            info?["eventId"] = eventId
        } else {
            info = ["chargeId": chargeId, "eventId": eventId]
        }
        FirebaseAPIService().cloudFunction(functionName: "refundCharge", method: "POST", params: info) { (results, error) in
            completion?(results, error)
        }
    }
    
    public func getStripeCustomers(completion: ((_ results: [String: String]) -> Void)?) {
        let queryRef = firRef.child("stripe_customers")
        queryRef.observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
                return
            }
            _stripeCustomers = snapshot.value as? [String: String] ?? [:]
            completion?(_stripeCustomers)
        }
    }
    
    public func playerIdForCustomer(_ customerId: String) -> String? {
        let result = _stripeCustomers.filter { (key, val) -> Bool in
            return val == customerId
        }
        if let playerId = result.first?.key {
            return playerId
        } else {
            return nil
        }
    }
}
