//
//  BaseService.swift
//  Balizinha
//
//  Created by Bobby Ren on 8/22/19.
//

import RxSwift
import RxCocoa
import FirebaseAuth
import RenderCloud
import RenderPay

public class BaseService {
    // FIXME: this sucks as a way to instantiate a default
    static var defaultAPIService: CloudAPIService & CloudDatabaseService & ServiceAPIProvider {
        return RenderAPIService(baseUrl: PannaServiceManager.baseUrl, baseRef: PannaServiceManager.baseRef)
    }
    internal let apiService: CloudAPIService & CloudDatabaseService & ServiceAPIProvider

    fileprivate var _objects: [String: FirebaseBaseModel] = [:]
    // read write queues
    // typically used for things like _events and _leagues
    internal let readWriteQueue = DispatchQueue(label: "readWriteQueue", attributes: .concurrent)
    
    // typically used for things like _userEvents and _playerLeagues
    internal let readWriteQueue2 = DispatchQueue(label: "readWriteQueue2", attributes: .concurrent)

    public init(apiService: (CloudAPIService & CloudDatabaseService & ServiceAPIProvider)? = nil) {
        let defaultService = BaseService.defaultAPIService
        self.apiService = apiService ?? defaultService
    }

    // individual id -> Object
    internal func cache(_ object: FirebaseBaseModel) {
        readWriteQueue.async(flags: .barrier) { [weak self] in
            self?._objects[object.id] = object
        }
    }
    
    internal func cached(_ objectId: String) -> FirebaseBaseModel? {
        var object: FirebaseBaseModel?
        readWriteQueue.sync { [weak self] in
            object = self?._objects[objectId]
        }
        return object
    }
    
    internal func getCachedObjects<T>() -> [T] {
        var results: [T] = []
        readWriteQueue.sync { [weak self] in
            if let self = self {
                results = Array(self._objects.values) as? [T] ?? []
            }
        }
        return results
    }
 
    public func resetOnLogout() {
        readWriteQueue.async(flags: .barrier) { [weak self] in
            self?._objects = [:]
        }
    }
    
    internal var refName: String {
        assertionFailure("refName ust be implemented by subclass")
        return ""
    }
    
    func createObject(from snapshot: Snapshot) -> FirebaseBaseModel? {
        assertionFailure("createObject must be implemented by subclass")
        return nil
    }

    @objc public func withId(id: String, completion: @escaping ((FirebaseBaseModel?)->Void)) {
        if let found = cached(id) {
            completion(found)
            return
        }

        let ref: Reference? = apiService.reference(at: refName)?.child(path: id)
        ref?.observeSingleValue{ [weak self] (snapshot) in
            guard snapshot.exists() else {
                completion(nil)
                return
            }
            ref?.removeAllObservers()
            if let object = self?.createObject(from: snapshot) {
                self?.cache(object)
                completion(object)
            } else {
                completion(nil)
            }
        }
    }

}
