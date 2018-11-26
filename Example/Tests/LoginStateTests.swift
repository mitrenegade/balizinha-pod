//
//  LoginStateTests.swift
//  Balizinha_Tests
//
//  Created by Bobby Ren on 11/25/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import Balizinha
import RxSwift

class LoginStateTests: XCTestCase {
    
    let defaultsProvider = MockDefaultsProvider()
    let authProvider = MockAuthProvider()
    var authService: AuthService!
    var disposeBag: DisposeBag!

    override func setUp() {
        authService = AuthService(defaults: defaultsProvider, auth: authProvider)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        authService = nil
        defaultsProvider.reset()
    }

    func testLoginStateIsLoggedOut() {
        let exp = expectation(description: "Login state is logged out")
        authService.loginState.asObservable().subscribe(onNext: { (state) in
            if case .loggedOut = state {
                exp.fulfill()
            }
        }).disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: nil)
    }
}
