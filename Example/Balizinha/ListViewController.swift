//
//  ListViewController.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 2/12/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCommunity
import Balizinha

class ListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    internal var refName: String {
        return ""
    }
    var objects: [FirebaseBaseModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        load()
    }

    func load() {
        let ref: DatabaseQuery
        ref = firRef.child(refName).queryOrdered(byChild: "createdAt")
        ref.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects = snapshot.children.allObjects as? [DataSnapshot] {
                self?.objects.removeAll()
                for dict: DataSnapshot in allObjects {
                    if let object = self?.createObject(from: dict) {
                        self?.objects.append(object)
                    }
                }
                self?.objects.sort(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.createdAt else { return false }
                    guard let t2 = p2.createdAt else { return true}
                    return t1 > t2
                })

                self?.reloadTable()
            }
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel {
        return FirebaseBaseModel(snapshot: snapshot)
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
