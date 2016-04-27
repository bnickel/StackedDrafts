//
//  PresenterSelectedLayout.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/26/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class PresenterSelectedLayout : UICollectionViewLayout {
    
    private var allAttributes:[UICollectionViewLayoutAttributes] = []
    private var contentSize = CGSizeZero
    
    override func prepareLayout() {
        
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections() == 1)
        
        let count = collectionView.numberOfItemsInSection(0)
        guard count > 0 else { return }
        
        let size = collectionView.frame.size
        
        let presenterAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: 0, inSection: 0))
        presenterAttributes.frame = CGRect(origin: CGPointZero, size: size)
        presenterAttributes.zIndex = 0
        
        var allAttributes = [presenterAttributes]
        
        for i in 1 ..< count {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            attributes.frame = CGRect(origin: CGPoint(x: 0, y: size.height - OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: OpenDraftsManager.sharedInstance.openDraftingViewControllers.count)), size: size)
            attributes.zIndex = i
            allAttributes.append(attributes)
        }
        
        self.allAttributes = allAttributes
        self.contentSize = size
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allAttributes.filter({ $0.frame.intersects(rect) })
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        precondition(indexPath.section == 0)
        return allAttributes[indexPath.item]
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes[indexPath.item]
    }
}
