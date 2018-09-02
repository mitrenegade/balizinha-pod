//
//  FirebaseImageService.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseStorage

fileprivate let storage = Storage.storage()
fileprivate let storageRef = storage.reference()
fileprivate let imageBaseRef = storageRef.child("images")

public class FirebaseImageService: NSObject {
    
    public enum ImageType: String {
        case player
        case event
        case league
    }
    
    fileprivate class func referenceForImage(type: ImageType, id: String) -> StorageReference? {
        return imageBaseRef.child(type.rawValue).child(id)
    }
    
    public class func uploadImage(image: UIImage, type: ImageType, uid: String, progressHandler: ((_ percent: Double)->Void)? = nil, completion: @escaping ((_ imageUrl: String?)->Void)) {
        guard let data = UIImageJPEGRepresentation(image, 0.9) else {
            completion(nil)
            return
        }
        
        let imageRef: StorageReference = imageBaseRef.child(type.rawValue).child(uid)
        let uploadTask = imageRef.putData(data, metadata: nil) { (meta, error) in
            if error != nil {
                completion(nil)
                return
            }
            imageRef.downloadURL(completion: { (url, error) in
                completion(url?.absoluteString)
            })
        }
        
        uploadTask.observe(.progress) { (storageTaskSnapshot) in
            if let progress = storageTaskSnapshot.progress {
                print("Progress \(progress)")
                let percent = progress.fractionCompleted
                progressHandler?(percent)
            }
        }
    }
    
    public class func resizeImage(image: UIImage, newSize: CGSize) -> UIImage? {
        // Guard newSize is different
        guard image.size != newSize else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    public class func resizeImageForProfile(image: UIImage) -> UIImage? {
        let size = image.size
        if size.width <= 500 || size.height <= 500 {
            return image
        }
        var width = size.width
        var height = size.height
        if width < height {
            height = 500 / width * height
            width = 500
        } else {
            width = 500 / height * width
            height = 500
        }
        let newSize = CGSize(width: width, height: height)
        print("Resizing image of \(size) to \(newSize)")
        return resizeImage(image: image, newSize: newSize)
    }
    
    public class func resizeImageForEvent(image: UIImage) -> UIImage? {
        // same conditions/size
        return resizeImageForProfile(image:image)
    }
    
    public func profileUrl(for id: String?, completion: @escaping ((URL?)->Void)) {
        guard let id = id else {
            completion(nil)
            return
        }
        let ref = FirebaseImageService.referenceForImage(type: .player, id: id)
        ref?.downloadURL(completion: { (url, error) in
            if let url = url {
                completion(url)
            } else {
                completion(nil)
            }
        })
    }
    
    public func leaguePhotoUrl(for id: String?, completion: @escaping ((URL?)->Void)) {
        guard let id = id else {
            completion(nil)
            return
        }
        let ref = FirebaseImageService.referenceForImage(type: .league, id: id)
        ref?.downloadURL(completion: { (url, error) in
            if let url = url {
                completion(url)
            } else {
                completion(nil)
            }
        })
    }
    
    public func eventPhotoUrl(for event: Event?, completion: @escaping ((URL?)->Void)) {
        guard let event = event else {
            completion(nil)
            return
        }
        let id = event.photoId ?? event.id
        let ref = FirebaseImageService.referenceForImage(type: .event, id: id)
        ref?.downloadURL(completion: { (url, error) in
            if let url = url {
                completion(url)
            } else {
                completion(nil)
            }
        })
    }
}
