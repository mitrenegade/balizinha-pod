//
//  MockDefaultsProvider.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import RxCocoa
import RxSwift

class MockDefaultsProvider: NSObject, DefaultsProvider {
    fileprivate var anyValueStream: BehaviorRelay<Any?> = BehaviorRelay<Any?>(value: nil)
    func valueStream(for key: DefaultsKey) -> BehaviorRelay<Any?>? {
        return anyValueStream
    }
    
    var dict: [String: Any] = [:]
    
    override func setValue(_ value: Any?, forKey key: String) {
        dict[key] = value
        anyValueStream.accept(value as? String)
    }
    
    override func value(forKey key: String) -> Any? {
        return dict[key]
    }
    
    func reset() {
        dict.removeAll()
    }
    
    
}
