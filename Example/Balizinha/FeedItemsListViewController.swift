//
//  FeedListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha
import Firebase

class FeedItemsListViewController: ListViewController {
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    // search/filter
    var pickerView: UIPickerView = UIPickerView()
    var searchTerm: String?
    @IBOutlet weak var containerSearch: UIView!
    @IBOutlet weak var inputSearch: UITextField!
    
    fileprivate var leagues: [League] = []
    fileprivate var leagueId: String?
    fileprivate var selectingLeagueId: String?
    fileprivate var selectingLeagueName: String?

    override var refName: String {
        return "feedItems"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Feed"
        
        pickerView.sizeToFit()
        pickerView.backgroundColor = .white
        pickerView.delegate = self
        pickerView.dataSource = self
        inputSearch.inputView = pickerView
        
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let next: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(selectLeague))
        keyboardNextButtonView.setItems([flex, cancel, next], animated: true)
        
        inputSearch.inputAccessoryView = keyboardNextButtonView
        
        inputSearch.placeholder = "Loading leagues..."
        LeagueService.shared.getLeagues { [weak self] (leagues) in
            self?.leagues = leagues
            self?.inputSearch.placeholder = "Select a league"
        }
    }
    
    @objc func cancelInput() {
        view.endEditing(true)
        selectingLeagueId = nil
        selectingLeagueName = nil
    }
    
    @objc func selectLeague() {
        leagueId = selectingLeagueId
        inputSearch.text = selectingLeagueName
        load()
        cancelInput()
    }
    
    override func load() {
        let ref: DatabaseQuery
        ref = firRef.child(refName)
        if let leagueId = leagueId {
            ref.queryEqual(toValue: leagueId, childKey: "leagueId")
        }
        ref.queryOrdered(byChild: "createdAt")
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
    
    override func createObject(from snapshot: DataSnapshot) -> FirebaseBaseModel? {
        let feedItem = FeedItem(snapshot: snapshot)
        if feedItem.visible {
            return feedItem
        }
        return nil
    }

}

extension FeedItemsListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < objects.count, let feedItem = objects[indexPath.row] as? FeedItem else { return UITableViewCell() }
        let identifier = feedItem.hasPhoto ? "FeedItemPhotoCell" : "FeedItemMessageCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! FeedItemCell
        cell.configure(feedItem: feedItem)
        return cell
    }
}

extension FeedItemsListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FeedItemsListViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return leagues.count + 1
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "All leagues"
        }
        let index = row - 1
        guard index < leagues.count else { return nil }
        return leagues[index].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            selectingLeagueId = nil
            selectingLeagueName = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        } else {
            let index = row - 1
            guard index < leagues.count else { return }
            selectingLeagueId = leagues[index].id
            selectingLeagueName = leagues[index].name
        }
    }
}
