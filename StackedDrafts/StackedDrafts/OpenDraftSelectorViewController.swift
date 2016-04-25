//
//  OpenDraftSelectorViewController.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class OpenDraftSelectorViewController: UIViewController {
    
    private let normalLayout = AllDraftsCollectionViewLayout()
    private var selectableViewControllers:[DraftViewControllerProtocol] = []
    
    private var collectionView:UICollectionView { return view as! UICollectionView }
    
    unowned let source: UIViewController
    
    init(source: UIViewController) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UICollectionView(frame: CGRectZero, collectionViewLayout: normalLayout)
        view.backgroundColor = UIColor.blackColor()
        view.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OpenDraftCollectionViewCell.register(with: collectionView)
        selectableViewControllers = OpenDraftsManager.sharedInstance.openDraftingViewControllers
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
}

extension OpenDraftSelectorViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + selectableViewControllers.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let view = OpenDraftCollectionViewCell.cell(at: indexPath, collectionView: collectionView)
        return view
    }
}

extension OpenDraftSelectorViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.view.bounds.size
    }
}

func * (a: CATransform3D, b: CATransform3D) -> CATransform3D {
    return CATransform3DConcat(a, b)
}

class AllDraftsCollectionViewLayout : UICollectionViewLayout {
    
    var verticalGap:CGFloat = 0.2 { didSet { invalidateLayout() } }
    
    private var pannedIndex:Int? = nil
    private var allAttributes:[UICollectionViewLayoutAttributes] = []
    private var contentSize = CGSizeZero
    
    override func prepareLayout() {
        super.prepareLayout()
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections() == 1)
        
        let size = collectionView.frame.size
        
        var topCenter = CGPoint(x: size.width / 2, y: 0)
        let scale = 1 - 12 / size.height
        
        var allAttributes:[UICollectionViewLayoutAttributes] = []
        
        for i in 0 ..< collectionView.numberOfItemsInSection(0) {
            
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            
            attributes.bounds = CGRect(origin: CGPointZero, size: size)
            attributes.zIndex = i
            attributes.transform3D = rotateDown(degrees: 61, itemHeight: size.height, scale: scale)
            attributes.center = topCenter
            attributes.center.y += topCenter.y - attributes.frame.minY
            
            var gap = verticalGap * size.height
            
            
            allAttributes.append(attributes)
            
            topCenter.y += gap
        }
        
        self.allAttributes = allAttributes
        
        if let lastAttribute = allAttributes.last {
            contentSize = CGSize(width: size.width, height: lastAttribute.frame.maxY)
        }
    }
    
    private func rotateDown(degrees angleInDegrees:CGFloat, itemHeight:CGFloat, scale:CGFloat) -> CATransform3D {
        
        let angleOfRotation:CGFloat = (-angleInDegrees / 180) * 3.1415926535
        let rotation = CATransform3DMakeRotation(angleOfRotation, 1, 0, 0)
        
        let translateDown = CATransform3DMakeTranslation(0, itemHeight / 2, 0)
        let translateUp = CATransform3DMakeTranslation(0, -itemHeight / 2, 0)
        let scale = CATransform3DMakeScale(scale, scale, scale)
        
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/1500
        
        return translateDown * rotation * scale * translateUp * perspective
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
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        precondition(indexPath.section == 0)
        let copy = allAttributes[indexPath.item].copy() as! UICollectionViewLayoutAttributes
        copy.alpha = 0
        return copy
    }
}