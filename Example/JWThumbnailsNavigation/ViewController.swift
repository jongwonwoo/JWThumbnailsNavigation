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
    weak var thumbnailsNavigation: JWThumbnailsNavigation!
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var photos: PHFetchResult<PHAsset>? {
        didSet {
            thumbnailsNavigation.setPhotos(self.photos)
        }
    }
    
    fileprivate var indexOfScrollingPhoto: Int = -1
    fileprivate var indexOfSelectedPhoto: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.makeThumbnailsNavigation()
        
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
    
    func makeThumbnailsNavigation() {
        let thumbnailsNavigation = JWThumbnailsNavigation.init(frame: CGRect.zero)
        toolbarView.addSubview(thumbnailsNavigation)
        
        thumbnailsNavigation.translatesAutoresizingMaskIntoConstraints = false
        thumbnailsNavigation.leadingAnchor.constraint(equalTo: self.toolbarView.leadingAnchor, constant: 0).isActive = true
        thumbnailsNavigation.trailingAnchor.constraint(equalTo: self.toolbarView.trailingAnchor, constant: 0).isActive = true
        thumbnailsNavigation.topAnchor.constraint(equalTo: self.toolbarView.topAnchor, constant: 0).isActive = true
        thumbnailsNavigation.bottomAnchor.constraint(equalTo: self.toolbarView.bottomAnchor, constant: 0).isActive = true
        
        self.thumbnailsNavigation = thumbnailsNavigation
        thumbnailsNavigation.delegate = self
        
    }
}

extension ViewController: JWThumbnailsNavigationDelegate {
    func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didScrollItemAt index: Int) {
        if indexOfScrollingPhoto != index {
            print("didScroll: \(index)")
            showPhotoAtInex(index, lowQuality: true)
            indexOfScrollingPhoto = index
        }
        
        indexOfSelectedPhoto = -1
    }
    
    func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didSelectItemAt index: Int) {
        if indexOfSelectedPhoto != index {
            print("didSelect: \(index)")
            showPhotoAtInex(index)
            indexOfSelectedPhoto = index
        }
    }
    
    func showPhotoAtInex(_ index: Int, lowQuality: Bool = false) {
        guard let photos = self.photos else { return }
        
        if 0 <= index && index < photos.count {
            let asset = photos[index]
            let itemSize = photoView.bounds.size
            let scale = UIScreen.main.scale
            let targetSize = CGSize.init(width: itemSize.width * scale, height: itemSize.height * scale)
            self.photoFetcher.fetchPhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, onlyLowQuality: lowQuality, completion: { image, isLowQuality in
                DispatchQueue.main.async {
                    print("showPhoto>>>>>: \(index), low quality: \(isLowQuality)")
                    self.photoView.image = image
                }
            })
        }
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
