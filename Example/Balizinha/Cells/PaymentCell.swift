//
//  PaymentCell.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import Balizinha

class PaymentCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelStatus: UILabel!
    
    func configure(payment: Payment, isEvent: Bool) {
        self.labelName.text = "Loading..." // payment.id
        let playerId: String? = isEvent ? payment.playerId : payment.firebaseKey
        if let id = playerId {
            print("Loading player with key \(id)")
            PlayerService.shared.withId(id: id, completion: { [weak self] (player) in
                self?.labelName.text = player?.name ?? player?.email ?? "Anon"
            })
        }

        if let amountString: String = payment.amountString {
            labelAmount.text = amountString
        } else {
            labelAmount.text = ""
        }

        labelDate.text = payment.createdAt?.dateString()
        
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
        case .unknown:
            labelStatus.text = "Status: \(payment.dict["status"])"
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
