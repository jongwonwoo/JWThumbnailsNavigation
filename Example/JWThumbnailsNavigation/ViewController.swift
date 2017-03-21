//
//  ViewController.swift
//  JWThumbnailsNavigation
//
//  Created by jongwonwoo on 03/21/2017.
//  Copyright (c) 2017 jongwonwoo. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var toolbarView: UIView!
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var photos: PHFetchResult<PHAsset>? {
        didSet {
            //TODO:
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestPhotoLibraryAuthorization(authorized: { [unowned self] in
            DispatchQueue.main.async {
                self.photos = self.photoFetcher.fetchPhotos()
                self.registerForPhotosDidChange()
            }
            }, denied: { [unowned self] in
                DispatchQueue.main.async {
                    self.openSettings()
                }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    fileprivate func registerForPhotosDidChange() {
        self.photoFetcher.photosDidChange { [unowned self] (photos: PHFetchResult<PHAsset>?, changes: PHFetchResultChangeDetails<PHAsset>?) in
            DispatchQueue.main.async {
                if let collectionChanges = changes {
                    self.photos = photos
                    
                    if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                        //TODO:
                    } else {
                        //TODO:
                    }
                }
            }
        }
    }
}

extension ViewController {
    fileprivate func requestPhotoLibraryAuthorization(authorized:(()->())?, denied:(()->())?) {
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
            switch status{
            case .authorized:
                if let authorizedBind = authorized {
                    authorizedBind()
                }
            case .denied:
                if let deniedBind = denied {
                    deniedBind()
                }
            default:
                break
            }
        })
    }
    
    fileprivate func openSettings() {
        let alertController = UIAlertController (title: "This App Would Like to Access Your Photos", message: "Used to see photos", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler:nil)
                } else {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        }
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
