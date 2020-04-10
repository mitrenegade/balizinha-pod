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
import PannaPay
import RxSwift
import RxCocoa

fileprivate enum MenuItem: String {
    case info
    case connect
}
class StripeMenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let connectService: StripeConnectService = Globals.connectService
    let paymentService: StripePaymentService = Globals.paymentService
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
        connectService.connectToAccount(userId)
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
                cell.textLabel?.text = "Current merchant account:"
                cell.detailTextLabel?.text = "\(connectService.accountState.value.description)"
            case .connect:
                cell.detailTextLabel?.text = nil
                switch connectService.accountState.value {
                case .none:
                    cell.textLabel?.text = "Click to connect your Stripe merchant account"
                case .loading:
                    cell.textLabel?.text = "Loading..."
                case .unknown:
                    cell.textLabel?.text = nil
                case .account:
                    cell.textLabel?.text = "Click to change your Stripe account"
                }
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
            switch connectService.accountState.value {
            case .account, .none:
                connectToStripe()
            default:
                return
            }
        }
    }
}
