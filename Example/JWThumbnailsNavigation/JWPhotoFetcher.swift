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
