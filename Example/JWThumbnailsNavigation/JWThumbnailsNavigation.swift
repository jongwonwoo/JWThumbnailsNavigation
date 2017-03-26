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
    fileprivate var lastIndexOfSelectedItem: Int = -1
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var photos: PHFetchResult<PHAsset>?
    
    func setPhotos(_ photos: PHFetchResult<PHAsset>?, andIndexOfSelectedItem indexOfSelectedItem: Int? = 0) {
        self.photos = photos
        
        self.thumbnailsCollectionView.reloadDataWithCompletion {
            self.thumbnailsCollectionView.reloadDataCompletionBlock = nil
            
            if let photos = self.photos, let indexOfSelectedItem = indexOfSelectedItem {
                if (0 <= indexOfSelectedItem && indexOfSelectedItem < photos.count) {
                    self.fireEventOnSelectThumbnailIndex(indexOfSelectedItem)
                    self.thumbnailsCollectionView.selectItem(at: IndexPath.init(item: indexOfSelectedItem, section: 0), animated: false, scrollPosition: .centeredHorizontally)
                }
            }
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
        
        self.scrollStateMachine.delegate = self
    }
    
}

extension JWThumbnailsNavigation: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func makeCollectionView() {
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
            self.photoFetcher.fetchPhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, onlyLowQuality: true, completion: { image, isLowQuality in
                DispatchQueue.main.async {
                    cell.image = image;
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        fireEventOnSelectThumbnailIndex(indexPath.item)
        
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
}

extension JWThumbnailsNavigation {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print(#function)
        scrollStateMachine.scrolling(.beginDragging)
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
                    
                    lastIndexOfSelectedItem = -1
                }
            }
        case .decelerating:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    //print("navigation didScroll: \(indexPath.item)")
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didScrollItemAt: indexPath.item)
                    
                    lastIndexOfSelectedItem = -1
                }
            }
        case .stop:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                fireEventOnSelectThumbnailIndex(indexPath.item)
            }
        default:
            break
        }
    }
    
    func fireEventOnSelectThumbnailIndex(_ index: Int) {
        if lastIndexOfSelectedItem != index {
            //print("navigation didSelect: \(index)")
            lastIndexOfSelectedItem = index
            delegate?.thumbnailsNavigation?(self, didSelectItemAt: index)
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
        var inset = CGFloat(0.0)
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        let cellWidth = viewHeight * 0.5
        inset = (viewWidth - cellWidth) / 2
        
        return UIEdgeInsets(top: 0.0, left: inset, bottom: 0.0, right: inset)
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
    
    func reloadDataWithCompletion(_ completion:@escaping () -> Void) {
        reloadDataCompletionBlock = completion
        super.reloadData()
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
