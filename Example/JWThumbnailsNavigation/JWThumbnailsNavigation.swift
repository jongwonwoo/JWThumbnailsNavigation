//
//  JWThumbnailsNavigation.swift
//  JWThumbnailsNavigation
//
//  Created by Jongwon Woo on 21/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos

@objc protocol JWThumbnailsNavigationDelegate {
    
    @objc optional func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didSelectItemAt index: Int)
    
}

class JWThumbnailsNavigation: UIView {

    weak var delegate: JWThumbnailsNavigationDelegate?
    
    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate weak var thumbnailsCollectionView: UICollectionView!
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var lastIndexOfSelectedItem: Int = 0
    
    var photos: PHFetchResult<PHAsset>? {
        didSet {
            thumbnailsCollectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    func setupView() {
        self.backgroundColor = .red
        
        self.makeCollectionView()
    }
    
}

extension JWThumbnailsNavigation: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func makeCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        collectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        self.thumbnailsCollectionView = collectionView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0;
        
        if let phots = self.photos {
            count = phots.count
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        
        if let photos = self.photos {
            let asset = photos[indexPath.item]
            let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let itemSize = collectionViewLayout.itemSize
            let scale = UIScreen.main.scale
            let targetSize = CGSize.init(width: itemSize.width * scale, height: itemSize.height * scale)
            self.photoFetcher.fetchPhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, completion: { image in
                DispatchQueue.main.async {
                    cell.image = image;
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //TODO; 선택한 셀을 가운데로 이동
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(#function)
        selectThumbnail()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            print(#function)
            selectThumbnail()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print(#function)
        selectThumbnail()
    }

    func selectThumbnail() {
        if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
            if lastIndexOfSelectedItem != indexPath.item {
                print("didSelect: \(indexPath.item)")
                lastIndexOfSelectedItem = indexPath.item
                delegate?.thumbnailsNavigation?(self, didSelectItemAt: indexPath.item)
            }
        }
    }
}

extension JWThumbnailsNavigation: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.bounds.height
        let width = height * 0.5
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}


private class ImageCollectionViewCell: UICollectionViewCell {
    private var imageView: UIImageView?
    
    var image: UIImage? {
        didSet {
            if self.imageView == nil {
                makeImageView()
            }
            
            self.imageView?.image = image
        }
    }
    
    private func makeImageView() {
        let imageView = UIImageView.init(frame: self.contentView.bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
        imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
        self.imageView = imageView
    }
}

private extension UICollectionView {
    func indexPathForVisibleCenter() -> IndexPath? {
        var visibleRect = CGRect()
        visibleRect.origin = self.contentOffset
        visibleRect.size = self.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return self.indexPathForItem(at: visiblePoint)
    }
}
