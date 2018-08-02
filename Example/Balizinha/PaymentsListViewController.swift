//
//  PaymentsListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

class PaymentsListViewController: ListViewController {
    
    @IBOutlet fileprivate weak var selectorType: UISegmentedControl!
    
    var data: [String: [Payment]] = [:]
    var events: [String: Event] = [:]

    override var refName: String {
        if selectorType.selectedSegmentIndex == 0 {
            return "charges/events"
        } else {
            return "charges/organizers"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Payments"
        
        selectorType.isHidden = true
    }
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel {
        return Payment(snapshot: snapshot)
    }
    
    @IBAction func toggleSelector(_ sender: UIControl) {
        data.removeAll()
        load()
    }
    
    override func load() {
        let ref = firRef.child(refName)
        ref.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                self?.data.removeAll()
                for categoryDict: DataSnapshot in allObjects {
                    let id = categoryDict.key
                    var payments = self?.data[id] ?? [Payment]()
                    let allPaymentDicts = categoryDict.children.allObjects as? [DataSnapshot] ?? []
                    for paymentDict: DataSnapshot in allPaymentDicts {
                        if let payment = self?.createObject(from: paymentDict) as? Payment{
                            payments.append(payment)
                        }
                    }
                    payments.sort(by: { (p1, p2) -> Bool in
                        guard let t1 = p1.createdAt else { return false }
                        guard let t2 = p2.createdAt else { return true}
                        return t1 > t2
                    })
                    self?.data[id] = payments
                    
                    EventService().withId(id: id, completion: { (event) in
                        if let event = event {
                            self?.events[id] = event
                            self?.reloadTable()
                        }
                    })
                }
            }
        }
    }
    
    fileprivate var keys: [String] {
        let allKeys = events.keys.enumerated()
        return allKeys.sorted(by: { p1, p2 in
            return events[p1.element]!.startTime! > events[p2.element]!.startTime!
        }).flatMap { $0.element }
    }
}

extension PaymentsListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let id = keys[section]
        let payments = data[id] ?? []
        return payments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath) as! PaymentCell
        let section = indexPath.section
        let row = indexPath.row

        let id = keys[section]
        let payments = data[id] ?? []

        if indexPath.row < payments.count {
            let payment = payments[row]
            cell.configure(payment: payment, isEvent: selectorType.selectedSegmentIndex == 0)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let id = keys[section]
        let view: PaymentHeaderView = PaymentHeaderView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
        if let event = events[id] {
            view.setup(with: event)
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
}

extension PaymentsListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        let section = indexPath.section
        let row = indexPath.row
        
        let id = keys[section]
        let payments = data[id] ?? []
        
        guard indexPath.row < payments.count else { return }
        guard let event = events[id] else { return }
        
        let payment = payments[row]
        if payment.status == .error {
            let errorString = payment.error ?? "Unknown error"
            
            let alert = UIAlertController(title: "Error summary", message: errorString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            // present options to refund
            let title = "Payment id: \(payment.id)"
            let message = "Amount: \(payment.amountString!)\nStatus: \(payment.status)\nEvent id: \(event.id)"
            print(title + message)
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Refund", style: .default, handler: { (action) in
                let alert = UIAlertController(title: "Please click confirm", message: "Are you sure you want to refund \(payment.amountString!)?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                    self.doRefund(chargeId: payment.id, eventId: event.id)
                }))
                self.present(alert, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                // none
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func doRefund(chargeId: String, eventId: String) {
        FirebaseAPIService().cloudFunction(functionName: "refundCharge", method: "POST", params: ["chargeId": chargeId, "eventId": eventId]) { (result, error) in
            print("FirebaseAPIService: result \(result) error \(error)")
            DispatchQueue.main.async {
                if let result = result {
                    let title = "Refund successful"
                    let message = "Result: \(result)"
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    self.tableView.reloadData()
                } else if let error = error as? NSError {
                    let title = "Refund error"
                    var message = "Error: \(error)"
                    if let errorMessage = error.userInfo["message"] as? String {
                        message = errorMessage
                    }
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    self.tableView.reloadData()
                }
            }
        }
    }
}
