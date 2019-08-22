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
    let readWriteQueue = DispatchQueue(label: "readWriteQueue", attributes: .concurrent)
    let objectIdQueue = DispatchQueue(label: "readWriteQueue", attributes: .concurrent)
    

}
