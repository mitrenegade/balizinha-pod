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
    @IBOutlet weak var buttonCancel: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refresh()
    }
    
    fileprivate func refresh() {
        guard let event = event else {
            labelInfo.text = "No event!"
            return
        }
        var string = "Event: \(event.id)\nAmount: \(event.amount!)"
        if paymentInfo == nil {
            buttonCapture.isEnabled = false
            buttonCancel.isEnabled = false
            string = "\(string)\nStatus: No payment"
            if let errorString = errorString {
                string = "Error: \(errorString)"
                buttonPay.isEnabled = false
            } else {
                buttonPay.isEnabled = true
            }
        } else if let chargeId = paymentInfo?["chargeId"], let status = paymentInfo?["status"] as? String, status == "succeeded" {
            string="\(string)\nCharge: \(chargeId)"
            if let captured = paymentInfo?["captured"] as? Bool, !captured {
                buttonPay.isEnabled = false
                buttonCapture.isEnabled = true
                buttonCancel.isEnabled = true
                string = "\(string)\nStatus: Hold"
            } else {
                buttonPay.isEnabled = false
                buttonCapture.isEnabled = false
                buttonCancel.isEnabled = true
                string = "\(string)\nStatus: \(status)"
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
        } else if button == buttonCancel {
            cancelPayment()
        }
    }
    
    fileprivate func submitPayment() {
        guard let player = PlayerService.shared.current.value else { return }
        guard let event = event else { return }
        let params = ["userId": player.id, "eventId": event.id]
        FirebaseAPIService().cloudFunction(functionName: "holdPayment", method: "POST", params: params) { (results, error) in
            print("Results \(String(describing: results)) error \(error)")
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
        let params: [String: Any] = ["userId": player.id, "eventId": event.id, "chargeId": charge["chargeId"]!]
        FirebaseAPIService().cloudFunction(functionName: "capturePayment", method: "POST", params: params) { (results, error) in
            print("Results \(String(describing: results)) error \(error)")
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
    
    fileprivate func cancelPayment() {
        
    }
}
