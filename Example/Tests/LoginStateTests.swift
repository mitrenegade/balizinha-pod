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
    
    let provider = MockDefaultsProvider()
    var authService: AuthService!
    var disposeBag: DisposeBag!

    override func setUp() {
        authService = AuthService(defaults: provider)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        authService = nil
        provider.reset()
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
