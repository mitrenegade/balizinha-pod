//
//  PaymentSubmitViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 8/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import RenderPay
import RenderCloud

class PaymentSubmitViewController: UIViewController {
    
    var event: Event?
    var paymentInfo: [String: Any]?
    var errorString: String?
    
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var buttonPay: UIButton!
    @IBOutlet weak var buttonCapture: UIButton!
    @IBOutlet weak var buttonRelease: UIButton!
    @IBOutlet weak var buttonRefund: UIButton!

    let paymentService: StripePaymentService = StripePaymentService(apiService: RenderAPIService())
    
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
            guard let player = PlayerService.shared.current.value else { return }
            guard let event = event else { return }
            paymentService.holdPayment(userId: player.id, eventId: event.id) { (results, error) in
                print("Hold payment Results \(String(describing: results)) error \(String(describing: error))")
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
        } else if button == buttonCapture {
            guard let player = PlayerService.shared.current.value else { return }
            guard let event = event, let charge = paymentInfo else { return }
            guard let chargeId = charge["chargeId"] as? String else { return }
            paymentService.capturePayment(userId: player.id, eventId: event.id, chargeId: chargeId, params: ["isAdmin": true])  { (results, error) in
                print("Capture payment Results \(String(describing: results)) error \(String(describing: error))")
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
        } else if button == buttonRelease || button == buttonRefund {
            guard let chargeId = paymentInfo?["chargeId"] as? String, let eventId = event?.id else { return }
            paymentService.refundPayment(eventId: eventId, chargeId: chargeId, params: ["isAdmin": true]) {(results, error) in
                let action = button == self.buttonRelease ? "Release" : "Refund"
                print("\(action) payment Results \(String(describing: results)) error \(String(describing: error))")
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
}
