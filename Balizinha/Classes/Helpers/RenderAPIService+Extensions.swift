//
//  RenderAPIService+Extensions.swift
//  RenderCloud
//
//  Created by Bobby Ren on 4/10/20.
//
//  This is a dependency inversion file to make RenderAPIService conform to the ServiceAPIProvider protocol needed by Balizinha's BaseService

import PannaPay
import RenderCloud

extension RenderAPIService: ServiceAPIProvider {
    public func stripeConnectAccounts(with userId: String) -> Reference? {
        return reference(with: "stripeConnectAccounts")?.child(path: userId)
    }
}
