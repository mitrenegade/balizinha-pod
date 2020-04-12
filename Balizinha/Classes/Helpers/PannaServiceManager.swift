//
//  PannaServiceManager.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/11/20.
//
//  Used to register requirements for RenderCloud, RenderPay (baseUrl, baseRef)
//  Cannot be used to initialize services that are not included in Balizinha Pod, such as Firebase, Google Services

import RenderCloud

public struct PannaServiceManager {
    static var baseUrl: String?
    static var baseRef: Reference?
    public static func configure(baseUrl: String?, baseRef: Reference?) {
        self.baseUrl = baseUrl
        self.baseRef = baseRef
    }
}
