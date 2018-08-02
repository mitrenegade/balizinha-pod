//
//  PlayerIcon.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Balizinha

class PlayerIcon: FirebaseModelIcon {

    override var photoUrl: String? {
        guard let player = object as? Player else { return nil }
        return player.photoUrl
    }

}

