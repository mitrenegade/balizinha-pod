//
//  RenderAPIService+Utils.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/3/19.
//

import UIKit
import RenderCloud

extension RenderAPIService {
    public func cloudFunction(functionName: String, params: [String: Any]?, completion: ((Any?, Error?) -> ())?) {
        cloudFunction(functionName: functionName, method: "POST", params: params, completion: completion)
    }
}
