//
//  DefaultsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/25/18.
//

import UIKit

public enum DefaultsKey: String {
    case guestUsername
    case guestEventId
}

public protocol DefaultsProvider {
    func value(forKey: String) -> Any?
    func setValue(_ value: Any?, forKey: String)
}

extension UserDefaults: DefaultsProvider {
    // already satisfies DefaultsProvider protocol by default
}
