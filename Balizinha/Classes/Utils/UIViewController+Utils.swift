//
//  UIViewController+Utils.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 5/8/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import Foundation
import UIKit

fileprivate let LOADING_VIEW_TAG = 25341
fileprivate let LOADING_INDICATOR_TAG = 25342
extension UIViewController {
    func showLoadingIndicator() {
        var frame = self.view.frame
        frame.origin.y = 0
        let view = UIView(frame: frame)
        view.tag = LOADING_VIEW_TAG
        view.backgroundColor = .black
        view.alpha = 0.5
        
        self.view.addSubview(view)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityIndicator.tag = LOADING_INDICATOR_TAG
        self.view.addSubview(activityIndicator)
    }
    
    func hideLoadingIndicator() {
        for view in self.view.subviews {
            if view.tag == LOADING_VIEW_TAG || view.tag == LOADING_INDICATOR_TAG {
                view.removeFromSuperview()
            }
        }
    }
}
