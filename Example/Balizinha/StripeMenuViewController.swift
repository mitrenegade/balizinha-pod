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
        case .connect: return "Connect account"
        }
    }
}
class StripeMenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var connectService: StripeConnectService?
    fileprivate var menuItems: [MenuItem] = [.info, .connect]
    var userId: String?
    var disposeBag: DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userId = userId else { return }

        // Do any additional setup after loading the view.
        let clientId = TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD
        connectService = StripeConnectService(clientId: clientId, apiService: FirebaseAPIService())
        connectService?.startListeningForAccount(userId: userId)
        connectService?.accountState.skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] state in
            print("StripeConnectService accountState changed: \(state)")
            self?.reloadTable()
        }).disposed(by: disposeBag)
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func connectToStripe() {
        guard let player = PlayerService.shared.current.value else { return }
        let userId = player.id
        guard let urlString = connectService?.getOAuthUrl(userId), let url = URL(string: urlString) else { return }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < menuItems.count {
            switch menuItems[indexPath.row] {
            case .info:
                cell.textLabel?.text = connectService?.accountState.value.description
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
