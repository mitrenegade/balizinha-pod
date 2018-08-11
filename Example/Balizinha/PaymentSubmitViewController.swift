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
        if paymentInfo == nil {
            buttonPay.isEnabled = true
            buttonCapture.isEnabled = false
            buttonCancel.isEnabled = false
        } else if let status = paymentInfo?["status"] as? String, status == "hold" {
            buttonPay.isEnabled = false
            buttonCapture.isEnabled = true
            buttonCancel.isEnabled = true
        } else if let status = paymentInfo?["status"] as? String, status == "complete" {
            buttonPay.isEnabled = false
            buttonCapture.isEnabled = false
            buttonCancel.isEnabled = true
        }
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
        FirebaseAPIService().cloudFunction(functionName: "submitPayment", method: "POST", params: params) { (results, error) in
            print("Results \(results) error \(error)")
        }
    }
    
    fileprivate func capturePayment() {
        
    }
    
    fileprivate func cancelPayment() {
        
    }
}
