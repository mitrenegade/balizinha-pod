//
//  APIProvider.swift
//  RenderCloud
//
//  Created by Bobby Ren on 4/10/20.
//

import RenderCloud

public protocol ServiceAPIProvider {
    func stripeConnectAccounts(with userId: String) -> Reference?
    var playersRef: Reference? { get }
}
