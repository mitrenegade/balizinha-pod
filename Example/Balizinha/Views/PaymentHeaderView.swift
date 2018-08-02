//
//  PaymentHeaderView.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 3/23/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
// Usage: Subclass your UIView from NibLoadView to automatically load a xib with the same name as your class

class PaymentHeaderView: NibLoadingView {
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDetails: UILabel!
    @IBOutlet weak var labelPayment: UILabel!

    func setup(with event: Event) {
        labelDate.text = event.dateString(event.startTime!) + " (id: \(event.id))"
        labelTitle.text = "\(event.name!) - \(event.locationString!)"
        labelDetails.text = event.info
        EventService().totalAmountPaid(for: event) { (amount, count) in
            let string = EventService.amountString(from: NSNumber(value: amount))!
            self.labelPayment.text = "\(string) paid by \(count) people"
        }
    }
}

@IBDesignable
class NibLoadingView: UIView {
    
    @IBOutlet weak var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    private func nibSetup() {
        backgroundColor = .clear
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return nibView
    }
    
}
