//
//  MenuViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/3/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import RxSwift
import Balizinha

fileprivate enum MenuItem: String {
    case players
    case events
    case actions
    case payments
    case leagues
    case cities
    case venues
    case feed
    case stripe
    case feedback
    case version
    case utils
    case map
    case login
    case logout
    
    var description: String {
        switch self {
        case .players: return "Players"
        case .events: return "Games"
        case .actions: return "Actions"
        case .payments: return "Payments"
        case .leagues: return "Leagues"
        case .cities: return "Cities (user entry)"
        case .venues: return "Venues and Cities"
        case .feed: return "Feed"
        case .stripe: return "Stripe Connect"
        case .feedback: return "Feedback/Inquiries"
        case .version: return "Version"
        case .utils: return "Utils"
        case .map: return "Player map"
        case .login: return "Login"
        case .logout: return "Logout"
        }
    }
}
fileprivate let loggedInMenu: [MenuItem] = [.players, .events, .actions, .payments, .leagues, .cities, .venues, .feed, .stripe, .feedback, .version, .utils, .map, .logout]
fileprivate let loggedOutMenu: [MenuItem] = [.login]

class MenuViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate var menuItems: [MenuItem] = loggedOutMenu
    
    // notifications
    var hasNewFeedback: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.title = "Balizinha Admin Menu"
        
        guard !AIRPLANE_MODE else {
            menuItems = loggedInMenu
            reloadTable()
            loadNotifications()
            return
        }

        AuthService.shared.startup()
        AuthService.shared.loginState.skip(1).subscribe(onNext: { [weak self] state in
            if state == .loggedOut {
                self?.menuItems = loggedOutMenu
                self?.reloadTable()
                self?.promptForLogin()
            } else {
                self?.menuItems = loggedInMenu
                self?.reloadTable()
                
                self?.loadNotifications()
            }
        }).disposed(by: disposeBag)
    }
    
    func promptForLogin() {
        let alert = UIAlertController(title: "Please Login", message: "Enter your email", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let email = textField.text, !email.isEmpty {
                self.promptForPassword(email: email)
            } else {
                print("Invalid email")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func promptForPassword(email: String) {
        let alert = UIAlertController(title: "Please Login", message: "Enter your password", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let password = textField.text, !password.isEmpty {
                self.doLogin(email: email, password: password)
            } else {
                print("Invalid password")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func doLogin(email: String, password: String) {
        AuthService.shared.loginUser(email: email, password: password) { [weak self] error in
            if let error = error {
                print("Error!")
                let alert = UIAlertController(title: "Login error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true)
            } else {
                print("Login success")
                let alert = UIAlertController(title: "Login success", message: nil, preferredStyle: .alert)
                self?.present(alert, animated: true)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
}

extension MenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < menuItems.count {
            cell.textLabel?.text = menuItems[indexPath.row].description
            
            switch menuItems[indexPath.row] {
            case .version:
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                cell.textLabel?.text = "Version: \(version ?? "unknown") (\(build ?? "unknown"))\(TESTING ? "t" : "")"
            case .feedback:
                if hasNewFeedback {
                    let notificationView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
                    let image = UIImage(named: "exclaimation")?.withRenderingMode(.alwaysTemplate)
                    notificationView.tintColor = .red
                    notificationView.image = image
                    cell.accessoryView = notificationView
                } else {
                    cell.accessoryView = nil
                }
            default:
                break
            }
        } else {
            cell.textLabel?.text = nil
        }
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < menuItems.count else { return }
        let selection = menuItems[indexPath.row]
        switch selection {
        case .login:
            promptForLogin()
        case .version:
            break
        case .logout:
            AuthService.shared.logout()
            reloadTable()
        default:
            performSegue(withIdentifier: selection.rawValue, sender: nil)
        }
    }
}

extension MenuViewController {
    // does some preloading to see if there are menu rows that should show a notification
    func loadNotifications() {
        FeedbackViewModel.checkForFeedback() { [weak self] hasNew in
            if hasNew != self?.hasNewFeedback {
                self?.hasNewFeedback = hasNew
                self?.reloadTable()
            }
        }
    }
}
