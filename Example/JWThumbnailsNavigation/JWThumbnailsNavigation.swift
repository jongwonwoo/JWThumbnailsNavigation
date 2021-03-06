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
    
    @objc optional func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didDragItemAt index: Int)
    @objc optional func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didScrollItemAt index: Int)
    @objc optional func thumbnailsNavigation(_ navigation: JWThumbnailsNavigation, didSelectItemAt index: Int)
    
}

class JWThumbnailsNavigation: UIView {

    weak var delegate: JWThumbnailsNavigationDelegate?
    
    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate weak var thumbnailsCollectionView: CustomCollectionView!
    
    fileprivate var scrollStateMachine: JWScrollStateMachine = JWScrollStateMachine()
    fileprivate var lastIndexOfScrollingItem: Int = -1
    fileprivate var indexPathOfSelectedItem: IndexPath? {
        willSet {
            guard let indexPath = indexPathOfSelectedItem else { return }
            
            if let cell = self.thumbnailsCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                cell.selectedCell = false
            }
        }
        didSet {
            guard let indexPath = indexPathOfSelectedItem else { return }
            
            if let cell = self.thumbnailsCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                cell.selectedCell = true
            }
        }
    }
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var photos: PHFetchResult<PHAsset>?
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        
        self.makeCollectionView()
        
        self.scrollStateMachine.delegate = self
    }
}

extension JWThumbnailsNavigation {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.thumbnailsCollectionView.collectionViewLayout.invalidateLayout()
        if let indexPath = indexPathOfSelectedItem {
            self.scrollToItem(at: indexPath)
        }
    }
}

extension JWThumbnailsNavigation {

    func setPhotos(_ photos: PHFetchResult<PHAsset>?, andIndexOfSelectedItem indexOfSelectedItem: Int? = 0) {
        self.photos = photos
        
        self.thumbnailsCollectionView.reloadDataWithCompletion {
            self.thumbnailsCollectionView.reloadDataCompletionBlock = nil
            
            if let photos = self.photos, let indexOfSelectedItem = indexOfSelectedItem {
                if (0 <= indexOfSelectedItem && indexOfSelectedItem < photos.count) {
                    self.selectThumbnailAtIndexPath(IndexPath.init(item: indexOfSelectedItem, section: 0), animated: false, fireEvent: false)
                }
            }
        }
    }
    
    func selectItem(atIndex index: Int, animated: Bool = false) {
        self.selectThumbnailAtIndexPath(IndexPath.init(item: index, section: 0), animated: animated, fireEvent: false)
    }

    fileprivate func selectThumbnailAtIndexPath(_ indexPath: IndexPath, animated: Bool, fireEvent: Bool) {
        if indexPathOfSelectedItem != indexPath {
            //print("navigation didSelect: \(index)")
            indexPathOfSelectedItem = indexPath

            if fireEvent {
                delegate?.thumbnailsNavigation?(self, didSelectItemAt: indexPath.item)
            }
        }
        
        self.scrollToItem(at: indexPath, animated: animated)
        
    }
    
    fileprivate func scrollToItem(at indexPath: IndexPath, animated: Bool = false) {
        guard let photos = self.photos else { return }
        
        if (0 <= indexPath.item && indexPath.item < photos.count) {
            self.thumbnailsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }
    
}

extension JWThumbnailsNavigation: UICollectionViewDataSource, UICollectionViewDelegate {
    
    fileprivate func makeCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = CustomCollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
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
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
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
            self.photoFetcher.fetchPhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, preferredLowQuality: false, completion: { image, isLowQuality in
                DispatchQueue.main.async {
                    cell.image = image;
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectThumbnailAtIndexPath(indexPath, animated: true, fireEvent: true)
    }
}

extension JWThumbnailsNavigation {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.beginDragging)
        
        indexPathOfSelectedItem = nil
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //print(#function)
        scrollStateMachine.scrolling(.willEndDragging)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.willBeginDecelerating)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.didScroll)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.didEndScrollingAnimation)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //print(#function)
        scrollStateMachine.scrolling(decelerate ? .didEndDraggingAndDecelerating : .didEndDraggingAndNotDecelerating)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.didEndDecelerating)
    }
}

extension JWThumbnailsNavigation: JWScrollStateMachineDelegate {
    func scrollStateMachine(_ stateMachine: JWScrollStateMachine, didChangeState state: JWScrollState) {
        //dump(state.rawValue)
        switch state {
        case .dragging:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    //print("navigation didDrag: \(indexPath.item)")
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didDragItemAt: indexPath.item)
                }
            }
        case .decelerating:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    //print("navigation didScroll: \(indexPath.item)")
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didScrollItemAt: indexPath.item)
                }
            }
        case .stop:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                selectThumbnailAtIndexPath(indexPath, animated: true, fireEvent: true)
            }
        default:
            break
        }
    }
}

extension JWThumbnailsNavigation: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.bounds.height - 2
        let width = height * 0.5
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insetX = CGFloat(1)
        var insetY = CGFloat(0)
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        let cellWidth = viewHeight * 0.5
        insetY = (viewWidth - cellWidth) / 2
        
        return UIEdgeInsets(top: insetX, left: insetY, bottom: insetX, right: insetY)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}

private class CustomCollectionView: UICollectionView {
    
    var reloadDataCompletionBlock: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reloadDataCompletionBlock?()
    }
    
    fileprivate func reloadDataWithCompletion(_ completion:@escaping () -> Void) {
        reloadDataCompletionBlock = completion
        super.reloadData()
    }
    
    fileprivate func indexPathForVisibleCenter() -> IndexPath? {
        var visibleRect = CGRect()
        visibleRect.origin = self.contentOffset
        visibleRect.size = self.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return self.indexPathForItem(at: visiblePoint)
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
    
    var selectedCell: Bool = false {
        didSet {
            if selectedCell {
                self.layer.borderColor = UIColor.white.cgColor
                self.layer.borderWidth = 3.0
            } else {
                self.layer.borderWidth = 0.0
            }
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
    
    override func prepareForReuse() {
        self.imageView?.image = nil
        self.selectedCell = false
    }
}
