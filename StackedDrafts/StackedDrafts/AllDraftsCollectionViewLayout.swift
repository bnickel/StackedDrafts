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

class AllDraftsCollectionViewLayout : UICollectionViewLayout {
    
    private var allAttributes:[UICollectionViewLayoutAttributes] = []
    private var contentSize = CGSizeZero
    private var changingBounds = false
    
    override func prepareLayout() {
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections() == 1)
        
        let count = collectionView.numberOfItemsInSection(0)
        let size = collectionView.frame.size
        
        var topCenter = CGPoint(x: size.width / 2, y: 40)
        let scale = 1 - 12 / size.height
        
        let clampedCount = max(2, min(count, 5))
        let verticalGap = (size.height - 80) / CGFloat(clampedCount)
        
        let angleInDegrees:CGFloat
        switch clampedCount {
        case 2:  angleInDegrees = 30
        case 3:  angleInDegrees = 45
        default: angleInDegrees = 61
        }
        
        var allAttributes:[UICollectionViewLayoutAttributes] = []
        
        for i in 0 ..< count {
            
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            let size = i == 0 ? size : UIEdgeInsetsInsetRect(CGRect(origin: CGPointZero, size: size), DraftPresentationController.presentedInsets).size
            
            attributes.bounds = CGRect(origin: CGPointZero, size: size)
            attributes.zIndex = i
            attributes.transform3D = rotateDown(degrees: angleInDegrees, itemHeight: size.height, scale: scale)
            attributes.center = topCenter
            
            allAttributes.append(attributes)
            
            topCenter.y += verticalGap
        }
        
        self.allAttributes = allAttributes
        
        if let lastAttribute = allAttributes.last {
            contentSize = CGSize(width: size.width, height: lastAttribute.frame.maxY - 40)
        }
    }
    
    private func rotateDown(degrees angleInDegrees:CGFloat, itemHeight:CGFloat, scale:CGFloat) -> CATransform3D {
        
        let angleOfRotation:CGFloat = (-angleInDegrees / 180) * 3.1415926535
        let rotation = CATransform3DMakeRotation(angleOfRotation, 1, 0, 0)
        
        let translateDown = CATransform3DMakeTranslation(0, itemHeight / 2, 0)
        let scale = CATransform3DMakeScale(scale, scale, scale)
        
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/1500
        
        return translateDown * rotation * scale * perspective
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allAttributes.filter({ $0.frame.intersects(rect) })
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes.indices.contains(indexPath.item) ? allAttributes[indexPath.item] : nil
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepareForAnimatedBoundsChange(oldBounds: CGRect) {
        changingBounds = true
        super.prepareForAnimatedBoundsChange(oldBounds)
    }
    
    override func finalizeAnimatedBoundsChange() {
        changingBounds = false
        super.finalizeAnimatedBoundsChange()
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes.indices.contains(indexPath.item) && !changingBounds ? allAttributes[indexPath.item] : nil
    }
}
