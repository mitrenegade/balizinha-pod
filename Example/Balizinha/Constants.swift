//
//  Constants.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import Balizinha
import RenderCloud
import RenderPay

let TESTING = true
let AIRPLANE_MODE = false

let STRIPE_CLIENT_ID_DEV = "ca_ECowy0cLCEaImKunoIsUfm2n4EbhxrMO"
let STRIPE_CLIENT_ID_PROD = "ca_ECowdoBb2DfRFlBMQSZ2jT4SSXAUJ6Lx"

let STRIPE_PUBLISHABLE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"
let STRIPE_PUBLISHABLE_KEY_PROD = "pk_live_IziZ9EDk1374oI3rXjEciLBG"

let FIREBASE_URL_DEV = "https://us-central1-balizinha-dev.cloudfunctions.net"
let FIREBASE_URL_PROD = "https://us-central1-balizinha-c9cd7.cloudfunctions.net"

let GOOGLE_API_KEY_PROD = "AIzaSyCr6wG6UZ9yhjlJbId0ErgkLrIdcYt11iU"

struct Globals {
    static let connectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD,
                                                     apiService: Globals.apiService,
                                                     baseRef: firRef)
    static let paymentService = StripePaymentService(apiService: Globals.apiService)
    static let apiService: CloudAPIService & CloudDatabaseService = RenderAPIService(baseUrl: TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD,
                                                       baseRef: firRef)
}
