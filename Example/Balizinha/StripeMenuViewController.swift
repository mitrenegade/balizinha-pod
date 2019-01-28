//
//  StripeMenuViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 1/26/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import RenderCloud
import Balizinha
import RenderPay
import RxSwift
import RxCocoa

fileprivate enum MenuItem: String {
    case info
    case connect
    
    var description: String {
        switch self {
        case .info: return "Account info"
        case .connect: return "Click to connect account"
        }
    }
}
class StripeMenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var connectService: StripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD, apiService: FirebaseAPIService())
    let paymentService: StripePaymentService = StripePaymentService(apiService: FirebaseAPIService())
    fileprivate var menuItems: [MenuItem] = [.info, .connect]
    var disposeBag: DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PlayerService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { [weak self] (player) in
            let userId = player.id
            
            guard let self = self else { return }
            
            // Do any additional setup after loading the view.
            self.connectService.startListeningForAccount(userId: userId)
            self.connectService.accountState.distinctUntilChanged().subscribe(onNext: { [weak self] state in
                print("StripeConnectService accountState changed: \(state)")
                self?.reloadTable()
            }).disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func connectToStripe() {
        guard let player = PlayerService.shared.current.value else { return }
        let userId = player.id
        guard let urlString = connectService.getOAuthUrl(userId), let url = URL(string: urlString) else { return }
        UIApplication.shared.openURL(url)
    }
}

extension StripeMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StripeMenuCell", for: indexPath)
        if indexPath.row < menuItems.count {
            switch menuItems[indexPath.row] {
            case .info:
                cell.textLabel?.text = "Current merchant account: \(connectService.accountState.value.description)"
            case .connect:
                cell.textLabel?.text = menuItems[indexPath.row].description
            }
        } else {
            cell.textLabel?.text = nil
        }
        return cell
    }
}

extension StripeMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < menuItems.count else { return }
        let selection = menuItems[indexPath.row]
        switch selection {
        case .info:
            return
        case .connect:
            connectToStripe()
        }
    }
}
