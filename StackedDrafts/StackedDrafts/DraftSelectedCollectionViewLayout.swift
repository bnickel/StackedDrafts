//
//  DraftSelectedCollectionViewLayout.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/26/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class DraftSelectedCollectionViewLayout: UICollectionViewLayout {
    
    var selectedIndex = 1 { didSet { invalidateLayout() } }
    
    private var allAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero
    
    override func prepare() {
        
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections == 1)
        
        let count = collectionView.numberOfItems(inSection: 0)
        guard count > 0 else { return }
        
        let size = collectionView.frame.size
        
        let presenterAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
        presenterAttributes.frame = CGRect(origin: .zero, size: size)
        presenterAttributes.zIndex = 0
        presenterAttributes.transform = DraftPresentationController.presenterTransform(height: size.height)
        presenterAttributes.alpha = DraftPresentationController.presenterAlpha
        
        var allAttributes = [presenterAttributes]
        
        for i in 1 ... selectedIndex {
            let indexPath = IndexPath(item: i, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), DraftPresentationController.presentedInsets)
            attributes.zIndex = i
            allAttributes.append(attributes)
        }
        
        for i in (selectedIndex + 1) ..< count {
            let indexPath = IndexPath(item: i, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(origin: CGPoint(x: 0, y: size.height), size: size)
            attributes.alpha = 0
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
