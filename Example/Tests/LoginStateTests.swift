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
    
    func testLoginStateIsGuestIfGuestEventIdExistsForAnonymousUser() {
        // store an eventId in defaults
        defaultsProvider.setValue("123", forKey: DefaultsKey.guestEventId.rawValue)

        // create a mock user that will return anonymous type
        let mockUser = MockUserType()
        mockUser.mockIsAnonymous = true
        authProvider.mockUser = mockUser

        let exp = expectation(description: "Anonymous user with an eventId is a guest")
        
        let loginState: Observable<LoginState> = authService.loginState.distinctUntilChanged().asObservable()
        let eventId: Observable<Any?> = defaultsProvider.valueStream(for: .guestEventId).distinctUntilChanged({ (val1, val2) -> Bool in
            let str1 = val1 as? String
            let str2 = val2 as? String
            return str1 != str2
        }).asObservable()
        
        Observable<Bool>.combineLatest(loginState, eventId, resultSelector: { state, eventId in
            let isGuest = state == .loggedOut && (eventId as? String) != nil
            print("State \(state) eventId \(String(describing: eventId)) isGuest \(isGuest)")
            return isGuest
        }).observeOn(MainScheduler.instance).subscribe(onNext: { (isGuest) in
            if isGuest {
                exp.fulfill()
            }
        }).disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
