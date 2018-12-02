//
//  DefaultsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/25/18.
//

import UIKit
import RxSwift
import RxCocoa

public enum DefaultsKey: String {
    case guestUsername
    case guestEventId
}

public protocol DefaultsProvider {
    func value(forKey: String) -> Any?
    func setValue(_ value: Any?, forKey: String)
    
    func valueStream(for key: DefaultsKey) -> BehaviorRelay<Any?>?
}

public class DefaultsManager: DefaultsProvider {
    public static let shared = DefaultsManager()
    
    public func value(forKey: String) -> Any? {
        return UserDefaults.standard.value(forKey: forKey)
    }
    
    public func setValue(_ value: Any?, forKey: String) {
        UserDefaults.standard.setValue(value, forKey: forKey)
        UserDefaults.standard.synchronize()
        
        if forKey == DefaultsKey.guestEventId.rawValue {
            guestEventId.accept(value)
        }
    }

    // Behavior relays to trigger an event when a default setting has been changed
    fileprivate var guestEventId: BehaviorRelay<Any?> = BehaviorRelay<Any?>(value: nil)
    
    // more general way to get a stream for a given key
    public func valueStream(for key: DefaultsKey) -> BehaviorRelay<Any?>? {
        if key == DefaultsKey.guestEventId {
            return guestEventId
        }
        return nil
    }
}
