//
//  FeedListViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 9/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Balizinha

class FeedItemsListViewController: ListViewController {

    override var refName: String {
        return "feedItems"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "Feed"
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

