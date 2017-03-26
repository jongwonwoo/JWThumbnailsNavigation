//
//  JWPhotoFetcher.swift
//  JWThumbnailsNavigation
//
//  Created by Jongwon Woo on 21/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos

class JWPhotoFetcher: NSObject, PHPhotoLibraryChangeObserver {
    fileprivate let imageManager = PHImageManager()
    var fetchResult: PHFetchResult<PHAsset>?
    var changeHandler: ((PHFetchResult<PHAsset>?, PHFetchResultChangeDetails<PHAsset>?) -> Void)?
    
    public override init() {
        super.init()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    func fetchPhotos() -> PHFetchResult<PHAsset>? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        self.fetchResult = PHAsset.fetchAssets(with: options)
        
        return self.fetchResult
    }
    
    func fetchPhoto(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, preferredLowQuality: Bool, completion: @escaping (UIImage?, Bool) -> Swift.Void) {
        self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: nil, resultHandler: { (result, info) in
            let isDegraded :NSNumber = info?[PHImageResultIsDegradedKey] as! NSNumber
            if (preferredLowQuality) {
                if (isDegraded.boolValue) {
                    completion(result, isDegraded.boolValue)
                }
            } else {
                completion(result, isDegraded.boolValue)
            }
        })
    }
    
    func photosDidChange(_ handler: @escaping (PHFetchResult<PHAsset>?, PHFetchResultChangeDetails<PHAsset>?) -> Void) {
        self.changeHandler = handler
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let handler = self.changeHandler,
            let fetchResult = self.fetchResult
            else { return }
        
        DispatchQueue.main.async {
            if let collectionChanges = changeInstance.changeDetails(for: fetchResult) {
                self.fetchResult = collectionChanges.fetchResultAfterChanges
                
                handler(self.fetchResult, collectionChanges)
            }
        }
    }
}
