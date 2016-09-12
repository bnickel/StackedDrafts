//
//  PresenterSelectedLayout.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/26/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class PresenterSelectedLayout : UICollectionViewLayout {
    
    fileprivate var allAttributes:[UICollectionViewLayoutAttributes] = []
    fileprivate var contentSize = CGSize.zero
    
    override func prepare() {
        
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections == 1)
        
        let count = collectionView.numberOfItems(inSection: 0)
        guard count > 0 else { return }
        
        let size = collectionView.frame.size
        
        let presenterAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
        presenterAttributes.frame = CGRect(origin: .zero, size: size)
        presenterAttributes.zIndex = 0
        
        var allAttributes = [presenterAttributes]
        
        for i in 1 ..< count {
            let indexPath = IndexPath(item: i, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(origin: CGPoint(x: 0, y: size.height - OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: OpenDraftsManager.sharedInstance.openDraftingViewControllers.count)), size: size)
            attributes.zIndex = i
            allAttributes.append(attributes)
        }
        
        self.allAttributes = allAttributes
        self.contentSize = size
    }
    
    override var collectionViewContentSize : CGSize {
        return contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allAttributes.filter({ $0.frame.intersects(rect) })
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        precondition(indexPath.section == 0)
        return allAttributes[indexPath.item]
    }
    
    override func initialLayoutAttributesForAppearingItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes[indexPath.item]
    }
}
