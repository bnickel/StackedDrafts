//
//  AllDraftsCollectionViewLayout.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/26/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

func * (a: CATransform3D, b: CATransform3D) -> CATransform3D {
    return CATransform3DConcat(a, b)
}

struct PannedItem {
    let indexPath: IndexPath
    var translation: CGPoint
}

class AllDraftsCollectionViewLayout : UICollectionViewLayout {
    
    private var allAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero
    private var changingBounds = false
    
    var pannedItem: PannedItem? { didSet { invalidateLayout() } }
    @NSCopying var lastPannedItemAttributes: UICollectionViewLayoutAttributes?
    var deletingPannedItem = false
    
    override func prepare() {
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections == 1)
        
        let count = collectionView.numberOfItems(inSection: 0)
        let size = collectionView.frame.size
        
        var topCenter = CGPoint(x: size.width / 2, y: 40)
        let scale = 1 - 12 / size.height
        
        let clampedCount = max(2, min(count, 5))
        let verticalGap = (size.height - 80) / CGFloat(clampedCount)
        
        let angleInDegrees: CGFloat
        switch clampedCount {
        case 2:  angleInDegrees = 30
        case 3:  angleInDegrees = 45
        default: angleInDegrees = 61
        }
        
        var allAttributes: [UICollectionViewLayoutAttributes] = []
        
        for i in 0 ..< count {
            
            let indexPath = IndexPath(item: i, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let size = i == 0 ? size : UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), DraftPresentationController.presentedInsets).size
            
            attributes.bounds = CGRect(origin: .zero, size: size)
            attributes.zIndex = i
            attributes.transform3D = rotateDown(degrees: angleInDegrees, itemHeight: size.height, scale: scale)
            attributes.center = topCenter
            
            let gapMultiplier: CGFloat
            if let pannedItem = pannedItem, pannedItem.indexPath.item == i {
                let delta = pannedItem.translation.x
                if delta > 0 {
                    attributes.center.x += sqrt(delta)
                    gapMultiplier = 1
                } else {
                    attributes.center.x += delta
                    gapMultiplier = 1 - abs(delta) / size.width
                }
                lastPannedItemAttributes = attributes
            } else {
                gapMultiplier = 1
            }
            
            allAttributes.append(attributes)
            topCenter.y += verticalGap * gapMultiplier
        }
        
        self.allAttributes = allAttributes
        
        if let lastAttribute = allAttributes.last {
            contentSize = CGSize(width: size.width, height: lastAttribute.frame.maxY - 40)
        }
    }
    
    private func rotateDown(degrees angleInDegrees: CGFloat, itemHeight: CGFloat, scale: CGFloat) -> CATransform3D {
        
        let angleOfRotation: CGFloat = (-angleInDegrees / 180) * .pi
        let rotation = CATransform3DMakeRotation(angleOfRotation, 1, 0, 0)
        
        let translateDown = CATransform3DMakeTranslation(0, itemHeight / 2, 0)
        let scale = CATransform3DMakeScale(scale, scale, scale)
        
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/1500
        
        return translateDown * rotation * scale * perspective
    }
    
    override var collectionViewContentSize : CGSize {
        return contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allAttributes.filter({ $0.frame.intersects(rect) })
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes.indices.contains(indexPath.item) ? allAttributes[indexPath.item] : nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
        changingBounds = true
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    override func finalizeAnimatedBoundsChange() {
        changingBounds = false
        super.finalizeAnimatedBoundsChange()
    }
    
    override func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes.indices.contains(indexPath.item) && !changingBounds ? allAttributes[indexPath.item] : nil
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let lastPannedItemAttributes = lastPannedItemAttributes , deletingPannedItem && lastPannedItemAttributes.indexPath == itemIndexPath, let collectionView = collectionView {
            lastPannedItemAttributes.center.x = -collectionView.frame.width / 2
            return lastPannedItemAttributes
        } else {
            return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        }
    }
}
