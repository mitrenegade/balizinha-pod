//
//  MockDefaultsProvider.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class MockDefaultsProvider: NSObject, DefaultsProvider {
    var dict: [String: Any] = [:]
    
    override func setValue(_ value: Any?, forKey key: String) {
        dict[key] = value
    }
    
    override func value(forKey key: String) -> Any? {
        return dict[key]
    }
    
    func reset() {
        dict.removeAll()
    }
}
