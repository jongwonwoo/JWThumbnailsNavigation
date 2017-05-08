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

    fileprivate let debug = false
    
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
    
    fileprivate var indexPathOfPrefferedItem: IndexPath?
    
    fileprivate let imageManager = PHImageManager()
    
    fileprivate var photos: Array<PHAsset>?
    
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
        self.layoutIfNeeded()
        
        if let indexPath = indexPathOfSelectedItem {
            self.scrollToItem(at: indexPath)
        }
    }
}

extension JWThumbnailsNavigation {

    func setPhotos(_ photos: Array<PHAsset>?, andIndexOfSelectedItem indexOfSelectedItem: Int = 0) {
        if debug {
            print(#function)
        }
        
        self.photos = photos
        let indexPath = IndexPath.init(item: indexOfSelectedItem, section: 0)
        self.indexPathOfPrefferedItem = indexPath
        
        self.thumbnailsCollectionView.reloadDataWithCompletion {
            if self.debug {
                print(#function)
            }
            self.thumbnailsCollectionView.reloadDataCompletionBlock = nil
            
            if let photos = self.photos {
                if (0 <= indexOfSelectedItem && indexOfSelectedItem < photos.count) {
                    self.selectThumbnailAtIndexPath(indexPath, fireEvent: false)
                    self.scrollToItem(at: indexPath, animated: false)
                }
            }
        }
    }
    
    func selectItem(atIndex index: Int, animated: Bool = false) {
        let selectedIndexPath = IndexPath.init(item: index, section: 0)
        
        self.selectThumbnailAtIndexPath(selectedIndexPath, fireEvent: false)
        self.scrollToItem(at: selectedIndexPath, animated: animated)
    }

    fileprivate func selectThumbnailAtIndexPath(_ indexPath: IndexPath, fireEvent: Bool) {
        indexPathOfPrefferedItem = indexPath
        
        if indexPathOfSelectedItem != indexPath {
            //print("navigation didSelect: \(index)")
            indexPathOfSelectedItem = indexPath

            if fireEvent {
                delegate?.thumbnailsNavigation?(self, didSelectItemAt: indexPath.item)
            }
        }
    }
    
    fileprivate func scrollToItem(at indexPath: IndexPath, animated: Bool = false) {
        if debug {
            print(#function)
        }
        
        guard let photos = self.photos else { return }
        
        if (0 <= indexPath.item && indexPath.item < photos.count) {
            let collectionViewLayout = self.thumbnailsCollectionView.collectionViewLayout as! JWThumbnailsNavigationFlowLayout
            if let attributes = collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                let centerX = self.thumbnailsCollectionView.bounds.size.width / 2
                let center = attributes.center
                let contentOffset = self.thumbnailsCollectionView.contentOffset
                
                let targetContentOffset = CGPoint(x: floor(center.x - centerX), y: contentOffset.y)
                self.thumbnailsCollectionView.setContentOffset(targetContentOffset, animated: animated)
                collectionViewLayout.targetContentOffset = targetContentOffset
            }
        }
    }
    
}

extension JWThumbnailsNavigation: UICollectionViewDataSource, UICollectionViewDelegate {
    
    fileprivate func makeCollectionView() {
        if debug {
            print(#function)
        }
        
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
        if debug {
            print(#function)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        
        if let photos = self.photos {
            let asset = photos[indexPath.item]
            let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let itemSize = collectionViewLayout.itemSize
            let scale = UIScreen.main.scale
            let targetSize = CGSize.init(width: itemSize.width * scale, height: itemSize.height * scale)
            self.fetchPhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, preferredLowQuality: false, completion: { image, isLowQuality in
                DispatchQueue.main.async {
                    cell.image = image;
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectThumbnailAtIndexPath(indexPath, fireEvent: true)
        scrollToItem(at: indexPath, animated: true)
    }
    
    
    func fetchPhoto(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, preferredLowQuality: Bool, completion: @escaping (UIImage?, Bool) -> Swift.Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = preferredLowQuality ? .fastFormat : .highQualityFormat
        
        self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: { (result, info) in
            //            dump(info)
            if result == nil {
                completion(nil, false)
                return
            }
            
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? NSNumber {
                completion(result, isDegraded.boolValue)
            } else {
                completion(result, false)
            }
        })
    }
}

extension JWThumbnailsNavigation {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.beginDragging)
        

        indexPathOfSelectedItem = nil
        indexPathOfPrefferedItem = nil
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if debug {
            print(#function)
        }
        scrollStateMachine.scrolling(.willEndDragging)
        
        if debug {
            print("original targetContentOffet: \(targetContentOffset.pointee.x),\(targetContentOffset.pointee.y)")
        }
        let centerX = self.thumbnailsCollectionView.bounds.size.width / 2
        let centerY = self.thumbnailsCollectionView.bounds.size.height / 2
        let x = targetContentOffset.pointee.x + centerX
        let y = targetContentOffset.pointee.y + centerY
        //FIXME: 셀 사이 여백에 걸려서 nil이 나오는 경우가 생김.
        indexPathOfPrefferedItem = self.thumbnailsCollectionView.indexPathForItem(at: CGPoint(x: x, y: y))
        
        if debug {
            print("targetContentOffet: \(x),\(y), \(String(describing: indexPathOfPrefferedItem))")
        }
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
        switch state {
        case .dragging:
            if let indexPath = self.thumbnailsCollectionView.jw_indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    if debug {
                        print("navigation didDrag: \(indexPath.item)")
                    }
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didDragItemAt: indexPath.item)
                }
            }
        case .decelerating:
            if let indexPath = self.thumbnailsCollectionView.jw_indexPathForVisibleCenter() {
                if lastIndexOfScrollingItem != indexPath.item {
                    if debug {
                        print("navigation didScroll: \(indexPath.item)")
                    }
                    lastIndexOfScrollingItem = indexPath.item
                    delegate?.thumbnailsNavigation?(self, didScrollItemAt: indexPath.item)
                }
            }
        case .stop:
            if let indexPath = self.thumbnailsCollectionView.jw_indexPathForVisibleCenter() {
                if debug {
                    print("navigation didSelect: \(indexPath.item)")
                }
                
                selectThumbnailAtIndexPath(indexPath, fireEvent: true)
            }
        default:
            break
        }
    }
}

extension JWThumbnailsNavigation: UICollectionViewDelegateFlowLayout, JWThumbnailsNavigationFlowLayoutDelegate {
    private func cellHeight() -> CGFloat {
        return self.bounds.height - 2
    }
    
    private func cellWidth(expanded: Bool) -> CGFloat {
        return expanded ? cellHeight() * 1.5 : cellHeight() * 0.5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if debug {
            print(#function)
        }
        
        let height = self.cellHeight()
        let width = self.cellWidth(expanded: false)
        
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, itemWidthAtIndexPath indexPath: IndexPath) -> (width: CGFloat, expandedWidth: CGFloat) {
        var expandedWidth = CGFloat(0)
        let width = self.cellWidth(expanded: false)
        
        if let targetIndexPath = self.indexPathOfPrefferedItem {
            if targetIndexPath == indexPath {
                expandedWidth = self.cellWidth(expanded: true) - width
                
                if debug {
                    print("itemWidthAtIndexPath")
//                dump(targetIndexPath)
//                dump(width)
//                dump(offsetX)
                }
            }
        }
        
        return (width, expandedWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if debug {
            print(#function)
        }
        
        let insetY = CGFloat(1)
        
        var insetX = CGFloat(0)
        let viewWidth = self.bounds.width
        let cellWidth = self.cellWidth(expanded: false)
        insetX = (viewWidth - cellWidth) / 2
        
        return UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if debug {
            print(#function)
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if debug {
            print(#function)
        }
        return 1
    }

    func collectionViewTargetIndexPath(_ collectionView: UICollectionView) -> IndexPath? {
        return self.indexPathOfPrefferedItem
    }
}

protocol JWThumbnailsNavigationFlowLayoutDelegate: NSObjectProtocol {
    
    func collectionViewTargetIndexPath(_ collectionView: UICollectionView) -> IndexPath?
    func collectionView(_ collectionView: UICollectionView, itemWidthAtIndexPath indexPath: IndexPath) -> (width: CGFloat, expandedWidth: CGFloat)
    
}


class JWThumbnailsNavigationFlowLayout: UICollectionViewFlowLayout {
    weak var delegate: JWThumbnailsNavigationFlowLayoutDelegate!
    var targetContentOffset: CGPoint?
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//        print(#function)
        
        let attributes = super.layoutAttributesForElements(in: rect)
        var attributesCopy = [UICollectionViewLayoutAttributes]()
        var attributesBeforeExpanedItem = [UICollectionViewLayoutAttributes]()
        
        let spacing: CGFloat = 1
        var offsetX: CGFloat = 0
        var passingExpandedItem = false
        var halfOfExpandedWidth: CGFloat = 0
        
        func expandFrame(_ frame: CGRect, width: CGFloat, expandedWidth: CGFloat, offsetX: CGFloat) -> CGRect {
            var expandedFrame: CGRect?
            
            if let targetContentOffset = self.targetContentOffset {
                if let contentOffset = collectionView?.contentOffset {
                    let threshold: CGFloat = 5
                    if abs(targetContentOffset.x - contentOffset.x) < threshold {
                        expandedFrame = expandFrame(frame, width: width, expandedWidth: expandedWidth)
                    }
                }
            } else {
                expandedFrame = expandFrame(frame, width: width, expandedWidth: expandedWidth)
            }
            
            if expandedFrame == nil {
                expandedFrame = modifyFrame(frame, width: width, offsetX: offsetX)
            }
            
            return expandedFrame!
        }
        
        func expandFrame(_ frame: CGRect, width: CGFloat, expandedWidth: CGFloat) -> CGRect {
            passingExpandedItem = true
            
            var expandedFrame = frame
            
            expandedFrame.size.width = width + expandedWidth
            
            if (0 < offsetX) {
                expandedFrame.origin.x = offsetX
            }
            halfOfExpandedWidth = expandedWidth / 2
            expandedFrame.origin.x -= halfOfExpandedWidth
            
            return expandedFrame
        }
        
        func modifyFrame(_ frame: CGRect, width: CGFloat, offsetX: CGFloat) -> CGRect {
            var modifiedFrame = frame
            
            modifiedFrame.size.width = width
            if (0 < offsetX) {
                modifiedFrame.origin.x = offsetX
            }
            
            return modifiedFrame
        }
        
        for itemAttributes in attributes! {
            let itemAttributesCopy = itemAttributes.copy() as! UICollectionViewLayoutAttributes
            
            var frame = itemAttributesCopy.frame
            let (width, expandedWidth) = delegate.collectionView(collectionView!, itemWidthAtIndexPath: itemAttributesCopy.indexPath)
            if 0 < expandedWidth {
                frame = expandFrame(frame, width: width, expandedWidth: expandedWidth, offsetX: offsetX)
            } else {
                frame = modifyFrame(frame, width: width, offsetX: offsetX)
            }
            
            offsetX = frame.maxX + spacing
            
            itemAttributesCopy.frame = frame
            
            attributesCopy.append(itemAttributesCopy)
            
            if !passingExpandedItem {
                attributesBeforeExpanedItem.append(itemAttributesCopy)
            }
        }
        
        for itemAttributes in attributesBeforeExpanedItem {
            var frame = itemAttributes.frame
            frame.origin.x = frame.origin.x - halfOfExpandedWidth
            itemAttributes.frame = frame
        }
        
        return attributesCopy
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//        print(#function)
        
        let center = collectionView!.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + center
        
        let layoutAttributes = self.layoutAttributesForElements(in: collectionView!.bounds)
        let closest = layoutAttributes!.sorted { abs($0.center.x - proposedContentOffsetCenterOrigin) < abs($1.center.x - proposedContentOffsetCenterOrigin) }.first ?? UICollectionViewLayoutAttributes()
        
        let targetContentOffset = CGPoint(x: floor(closest.center.x - center), y: proposedContentOffset.y)
        
        self.targetContentOffset = targetContentOffset
        
        return targetContentOffset
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
}

private extension UICollectionView {
    func jw_indexPathForVisibleCenter() -> IndexPath? {
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
