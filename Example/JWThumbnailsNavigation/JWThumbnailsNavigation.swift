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

    fileprivate let debug = true
    
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
    
    fileprivate var indexPathOfTargetContentOffset: IndexPath?
    
    fileprivate let photoFetcher = JWPhotoFetcher()
    fileprivate var photos: PHFetchResult<PHAsset>?
    
    func setPhotos(_ photos: PHFetchResult<PHAsset>?, andIndexOfSelectedItem indexOfSelectedItem: Int? = 0) {
        self.photos = photos
        
        self.thumbnailsCollectionView.reloadDataWithCompletion {
            self.thumbnailsCollectionView.reloadDataCompletionBlock = nil
            
            if let photos = self.photos, let indexOfSelectedItem = indexOfSelectedItem {
                if (0 <= indexOfSelectedItem && indexOfSelectedItem < photos.count) {
                    self.selectThumbnailAtIndexPath(IndexPath.init(item: indexOfSelectedItem, section: 0), scrolling: true, animated: false)
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
    
    
    fileprivate func selectThumbnailAtIndexPath(_ indexPath: IndexPath, scrolling: Bool, animated: Bool) {
        fireEventOnSelectThumbnailIndexPath(indexPath)
        if scrolling {
            self.thumbnailsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        }
    }
    
    private func fireEventOnSelectThumbnailIndexPath(_ indexPath: IndexPath) {
        if indexPathOfSelectedItem != indexPath {
            //print("navigation didSelect: \(index)")
            indexPathOfSelectedItem = indexPath
            delegate?.thumbnailsNavigation?(self, didSelectItemAt: indexPath.item)
        }
    }
    
}

extension JWThumbnailsNavigation: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func makeCollectionView() {
        let layout = JWThumbnailsNavigationFlowLayout()
        layout.delegate = self
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
        selectThumbnailAtIndexPath(indexPath, scrolling: true, animated: false)
    }
}

extension JWThumbnailsNavigation {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.beginDragging)
        
        indexPathOfTargetContentOffset = nil
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.willEndDragging)
        
        let center = self.thumbnailsCollectionView.bounds.size.width / 2
        let x = targetContentOffset.pointee.x + center
        let y = targetContentOffset.pointee.y
        
        indexPathOfTargetContentOffset = self.thumbnailsCollectionView.indexPathForItem(at: CGPoint(x: x, y: y))
        print("targetContentOffet: \(x),\(y), \(indexPathOfTargetContentOffset)")
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.willBeginDecelerating)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.didScroll)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.didEndScrollingAnimation)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(decelerate ? .didEndDraggingAndDecelerating : .didEndDraggingAndNotDecelerating)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
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
                    if debug {
                        print("navigation didDrag: \(indexPath.item)")
                    }
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didDragItemAt: indexPath.item)
                    
                    indexPathOfSelectedItem = nil
                }
            }
        case .decelerating:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    if debug {
                        print("navigation didScroll: \(indexPath.item)")
                    }
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didScrollItemAt: indexPath.item)
                    
                    indexPathOfSelectedItem = nil
                }
            }
        case .stop:
            if let indexPath = self.thumbnailsCollectionView.indexPathForVisibleCenter() {
                if debug {
                    print("navigation didSelect: \(indexPath.item)")
                    selectThumbnailAtIndexPath(indexPath, scrolling: false, animated: false)
                }
            }
        default:
            break
        }
    }
}

extension JWThumbnailsNavigation: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.bounds.height
        var width = height * 0.5
        if let indexPathOfTargetContentOffset = indexPathOfTargetContentOffset {
            if indexPath == indexPathOfTargetContentOffset {
                width += height
            }
        }
        
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

extension JWThumbnailsNavigation: JWThumbnailsNavigationFlowLayoutDelegate {

    func collectionViewTargetIndexPath(_ collectionView: UICollectionView) -> IndexPath? {
        return self.indexPathOfTargetContentOffset
    }
}

protocol JWThumbnailsNavigationFlowLayoutDelegate {
    
    func collectionViewTargetIndexPath(_ collectionView: UICollectionView) -> IndexPath?
    
}


class JWThumbnailsNavigationFlowLayout: UICollectionViewFlowLayout {
    var delegate: JWThumbnailsNavigationFlowLayoutDelegate!
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        print(#function)
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var expanded = false
        var offsetX: CGFloat = 0
        for itemAttributes in attributes! {
            var frame = itemAttributes.frame
            if expanded {
                frame.origin.x = frame.minX + offsetX
            }
            
            if let indexPath = delegate.collectionViewTargetIndexPath(collectionView!) {
                if indexPath == itemAttributes.indexPath {
                    frame.size.width = collectionView!.frame.height * 0.5 + collectionView!.frame.height
                    expanded = true
                    offsetX = collectionView!.frame.height
                } else {
                    frame.size.width = collectionView!.frame.height * 0.5
                }
            } else {
                frame.size.width = collectionView!.frame.height * 0.5
            }
            
            itemAttributes.frame = frame
            print("\(itemAttributes.indexPath):::::\(frame)")
        }
        
        return attributes
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let layoutAttributes = self.layoutAttributesForElements(in: collectionView!.bounds)
        
        let center = collectionView!.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + center
        
        let closest = layoutAttributes!.sorted { abs($0.center.x - proposedContentOffsetCenterOrigin) < abs($1.center.x - proposedContentOffsetCenterOrigin) }.first ?? UICollectionViewLayoutAttributes()
        
        let targetContentOffset = CGPoint(x: floor(closest.center.x - center) , y: proposedContentOffset.y)
        
        return targetContentOffset
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

private extension UICollectionView {
    func indexPathForVisibleCenter() -> IndexPath? {
        var visibleRect = CGRect()
        visibleRect.origin = self.contentOffset
        visibleRect.size = self.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return self.indexPathForItem(at: visiblePoint)
    }
}
