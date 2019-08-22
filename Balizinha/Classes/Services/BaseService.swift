//
//  BaseService.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/22/19.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import RenderCloud

fileprivate var singleton: EventService?

public class BaseService {
    // read write queues
    // typically used for things like _events and _leagues
    let readWriteQueue = DispatchQueue(label: "readWriteQueue", attributes: .concurrent)
    
    // typically used for things like _userEvents and _playerLeagues
    let readWriteQueue2 = DispatchQueue(label: "readWriteQueue2", attributes: .concurrent)
}
