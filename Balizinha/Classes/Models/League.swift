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
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var city: String? {
        get {
            return self.dict["city"] as? String
        }
        set {
            self.dict["city"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
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
            self.dict["info"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    public var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var tags: [String] {
        get {
            return self.dict["tags"] as? [String] ?? []
        }
        set {
            self.dict["tags"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var isPrivate: Bool {
        get {
            return self.dict["isPrivate"] as? Bool ?? false
        }
        set {
            self.dict["isPrivate"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    public var owner: String? {
        get {
            if let val = self.dict["owner"] as? String {
                return val
            }
            return nil
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
