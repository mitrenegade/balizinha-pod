//
//  LeagueListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCore
import Balizinha
import FirebaseDatabase

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
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel? {
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.row < objects.count else {
            return
        }
        guard let league = objects[indexPath.row] as? League else { return }
        
        if editingStyle == .delete {
            let name: String = league.name ?? ""
            let alert = UIAlertController(title: "Delete league", message: "Are you sure you want to delete league \(league.id) \(name)? This cannot be undone.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action) in
                if let index = self.objects.firstIndex(of: league) {
                    LeagueService.delete(league)
                    self.objects.remove(at: index)
                    self.tableView.reloadData()
                } else {
                    print("Could not delete league")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
}

extension LeagueListViewController: LeagueViewDelegate {
    func didUpdate() {
        load()
        navigationController?.popToViewController(self, animated: true)
    }
}

