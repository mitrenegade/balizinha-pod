//
//  LeagueListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

class LeagueListViewController: ListViewController {
    override var refName: String {
        return "leagues"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Leagues"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createLeague))
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel {
        return League(snapshot: snapshot)
    }
    
    @objc fileprivate func createLeague() {
        performSegue(withIdentifier: "toLeague", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLeague", let controller = segue.destination as? LeagueEditViewController {
            if let league = sender as? League {
                controller.league = league
            }
            controller.delegate = self
        }
    }
}

extension LeagueListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeagueCell", for: indexPath) as! LeagueCell
        if indexPath.row < objects.count {
            if let league = objects[indexPath.row] as? League {
                cell.configure(league: league)
            }
        }
        return cell
    }
}

extension LeagueListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let league = objects[indexPath.row] as? League else { return }
        performSegue(withIdentifier: "toLeague", sender: league)
    }
}

extension LeagueListViewController: LeagueViewDelegate {
    func didUpdate() {
        load()
        navigationController?.popToViewController(self, animated: true)
    }
}

