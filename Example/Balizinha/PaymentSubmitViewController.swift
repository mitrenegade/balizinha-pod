//
//  PaymentSubmitViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 8/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class PaymentSubmitViewController: UIViewController {
    
    var event: Event?
    var paymentInfo: [String: Any]?
    var errorString: String?
    
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var buttonPay: UIButton!
    @IBOutlet weak var buttonCapture: UIButton!
    @IBOutlet weak var buttonRelease: UIButton!
    @IBOutlet weak var buttonRefund: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refresh()
    }
    
    fileprivate func refresh() {
        guard let event = event else {
            labelInfo.text = "No event!"
            buttonCapture.isEnabled = false
            buttonPay.isEnabled = false
            buttonRelease.isEnabled = false
            buttonRefund.isEnabled = false
            return
        }
        var string = "Event: \(event.id)\nAmount: \(event.amount!)"
        if paymentInfo == nil {
            buttonCapture.isEnabled = false
            buttonRelease.isEnabled = false
            buttonRefund.isEnabled = false
            string = "\(string)\nStatus: No payment"
            if let errorString = errorString {
                string = "Error: \(errorString)"
                buttonPay.isEnabled = false
            } else {
                buttonPay.isEnabled = true
            }
        } else if let chargeId = paymentInfo?["chargeId"], let status = paymentInfo?["status"] as? String, status == "succeeded" {
            buttonPay.isEnabled = false

            string="\(string)\nCharge: \(chargeId)"
            let captured = paymentInfo?["captured"] as? Bool ?? false
            let refunded = paymentInfo?["refunded"] as? Bool ?? false
            switch (captured, refunded) {
            case (false, false):
                buttonCapture.isEnabled = true
                buttonRelease.isEnabled = true
                buttonRefund.isEnabled = false
                string = "\(string)\nStatus: Hold"
            case (true, false):
                buttonCapture.isEnabled = false
                buttonRelease.isEnabled = false
                buttonRefund.isEnabled = true
                string = "\(string)\nStatus: captured"
            case (_, true):
                buttonCapture.isEnabled = false
                buttonRelease.isEnabled = false
                buttonRefund.isEnabled = false
                string = "\(string)\nStatus: refunded"
            }
            
        }

        labelInfo.text = string
    }
    
    @IBAction func didClickButton(_ sender: Any?) {
        guard let button = sender as? UIButton else { return }
        if button == buttonPay {
            submitPayment()
        } else if button == buttonCapture {
            capturePayment()
        } else if button == buttonRelease {
            releasePayment()
        } else if button == buttonRefund {
            refundPayment()
        }
    }
    
    fileprivate func submitPayment() {
        guard let player = PlayerService.shared.current.value else { return }
        guard let event = event else { return }
        let params = ["userId": player.id, "eventId": event.id]
        FirebaseAPIService().cloudFunction(functionName: "holdPayment", method: "POST", params: params) { (results, error) in
            print("Submit payment Results \(String(describing: results)) error \(error)")
            if let error = error as NSError? {
                self.errorString = error.userInfo["error"] as? String
                self.paymentInfo = nil
            } else {
                self.paymentInfo = results as? [String: Any]
                self.errorString = nil
            }
            DispatchQueue.main.async {
                self.refresh()
            }
        }
    }
    
    fileprivate func capturePayment() {
        guard let player = PlayerService.shared.current.value else { return }
        guard let event = event, let charge = paymentInfo else { return }
        let params: [String: Any] = ["userId": player.id, "eventId": event.id, "chargeId": charge["chargeId"]!, "isAdmin": true ]
        FirebaseAPIService().cloudFunction(functionName: "capturePayment", method: "POST", params: params) { (results, error) in
            print("Capture payment Results \(String(describing: results)) error \(error)")
            if let error = error as NSError? {
                self.errorString = error.userInfo["error"] as? String
                self.paymentInfo = nil
            } else {
                self.paymentInfo = results as? [String: Any]
                self.errorString = nil
            }
            DispatchQueue.main.async {
                self.refresh()
            }
        }
    }
    
    fileprivate func releasePayment() {
        refundPayment()
    }

    fileprivate func refundPayment() {
        guard let chargeId = paymentInfo?["chargeId"], let eventId = event?.id else { return }
        FirebaseAPIService().cloudFunction(functionName: "refundCharge", method: "POST", params: ["chargeId": chargeId, "eventId": eventId]) { (results, error) in
            print("Refund/release payment: result \(results) error \(error)")
            if let error = error as NSError? {
                self.errorString = error.userInfo["error"] as? String
                self.paymentInfo = nil
            } else {
                self.paymentInfo = results as? [String: Any]
                self.errorString = nil
            }
            DispatchQueue.main.async {
                self.refresh()
            }
        }
    }
}
