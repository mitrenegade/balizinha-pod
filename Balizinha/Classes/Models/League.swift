//
//  League.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import UIKit
import FirebaseCore
import RxSwift

public class League: FirebaseBaseModel {
    public var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            update(key: "name", value: newValue)
        }
    }
    
    public var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            update(key: "city", value: newValue)
        }
    }
    
    public var info: String {
        get {
            if let val = self.dict["info"] as? String {
                return val
            }
            return ""
        }
        set {
            update(key: "info", value: newValue)
        }
    }

    public var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            update(key: "photoUrl", value: newValue)
        }
    }
    
    public var tags: [String] {
        get {
            return self.dict["tags"] as? [String] ?? []
        }
        set {
            update(key: "tags", value: newValue)
        }
    }
    
    public var isPrivate: Bool {
        get {
            return self.dict["isPrivate"] as? Bool ?? false
        }
        set {
            update(key: "isPrivate", value: newValue)
        }
    }
    
    public var ownerId: String? {
        return dict["ownerId"] as? String ?? dict["owner"] as? String
    }
    
    public var playerCount: Int {
        let count = self.dict["playerCount"] as? Int ?? 0
        if count < 0 {
            return 0
        }
        return count
    }

    public var eventCount: Int {
        let count = self.dict["eventCount"] as? Int ?? 0
        if count < 0 {
            return 0
        }
        return count
    }
    
    public var shareLink: String? {
        get {
            return self.dict["shareLink"] as? String
        }
    }
}

// MARK: - Tags
extension League {
    public var tagString: String {
        var string: String = ""
        tags.forEach { tag in
            if string.isEmpty {
                string = tag
            } else {
                string = string + ", " + tag
            }
        }
        return string
    }
    
    public class func tags(from tagString: String) -> [String] {
        let set = CharacterSet.alphanumerics.union([" "])
        let filtered = String(tagString.unicodeScalars.filter { set.contains($0) })
        let tokens = filtered.components(separatedBy: [" "])
        return tokens
    }
}


// MARK: - Rankings and info
extension League {
    public var pointCount: Int {
        // point calculation: number of active games * 2 + number of past games + number of players
        return 12
    }

    public var rating: Double {
        return 4.5
    }
}

extension League {
    //***************** hack: for test purposes only
    public class func random() -> League {
        let league = League()
        league.dict = ["name": "My Awesome League", "city": league.randomPlace(), "tags": "fake, league", "info": "this is my airplane league"]
        return league
    }
    
    fileprivate func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
