//
//  PannaServiceManager.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/11/20.
//
//  Used to register requirements for RenderCloud, RenderPay (baseUrl, baseRef)
//  Cannot be used to initialize services that are not included in Balizinha Pod, such as Firebase, Google Services

import RenderCloud
import RenderPay

public struct PannaServiceManager {
    static var baseUrl: String?
    static var baseRef: Reference?
    static var stripeClientId: String!
    public static func configure(baseUrl: String?, baseRef: Reference?, stripeClientId: String) {
        PannaServiceManager.baseUrl = baseUrl
        PannaServiceManager.baseRef = baseRef
        assert(stripeClientId != nil, "Did you forget to set a stripe clientId")
        PannaServiceManager.stripeClientId = stripeClientId
    }
    
    static var apiService = RenderAPIService(baseUrl: PannaServiceManager.baseUrl,
                                             baseRef: PannaServiceManager.baseRef)
    static var stripeConnectService: StripeConnectService = StripeConnectService(clientId:PannaServiceManager.stripeClientId, apiService: PannaServiceManager.apiService)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: PannaServiceManager.apiService)

}
