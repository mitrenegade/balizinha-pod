//
//  PaymentCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha
import RenderPay

class PaymentCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelStatus: UILabel!
    
    func configure(payment: Payment, isEvent: Bool) {
        labelName.text = "Loading..." // payment.id
        let playerId: String? = isEvent ? payment.playerId : payment.firebaseKey
        if let id = playerId {
            print("Loading player with key \(id)")
            PlayerService.shared.withId(id: id, completion: { [weak self] (player) in
                self?.labelName.text = player?.name ?? player?.email ?? "Unknown player"
            })
        } else if let customerId = payment.customerId, let playerId = StripePaymentService().playerIdForCustomer(customerId) {
            PlayerService.shared.withId(id: playerId, completion: { [weak self] (player) in
                self?.labelName.text = player?.name ?? player?.email ?? "Unknown player"
            })
        } else {
            labelName.text = "PaymentId: \(payment.id)"
        }

        if let amountString: String = payment.amountString {
            labelAmount.text = amountString
        } else {
            labelAmount.text = "No amount specified"
        }

        labelDate.text = payment.createdAt?.dateString() ?? "Unknown date"
        
        // status
        switch payment.status {
        case .succeeded:
            labelStatus.text = "Single payment"
            labelStatus.textColor = .green
            self.accessoryType = .none
        case .active:
            labelStatus.text = "Subscription"
            labelStatus.textColor = .green
            self.accessoryType = .none
        case .error:
            labelStatus.text = "Error"
            labelStatus.textColor = .red
            self.accessoryType = .disclosureIndicator
        case .hold:
            labelStatus.text = "Authorized/Hold"
            labelStatus.textColor = .blue
            self.accessoryType = .disclosureIndicator
        case .unknown:
            labelStatus.text = "Unknown status: \(String(describing: payment.dict["status"]))"
            labelStatus.textColor = .darkGray
            self.accessoryType = .none
        case .partialRefund:
            labelStatus.text = "Partial refund"
            labelStatus.textColor = .orange
            self.accessoryType = .none
        case .refunded:
            labelStatus.text = "Full refund"
            labelStatus.textColor = .orange
            self.accessoryType = .none
        }
    }
}
