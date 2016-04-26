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
    private let initialLayout = PresenterSelectedLayout()
    private let draftSelectedLayout = DraftSelectedCollectionViewLayout()
    private var selectableViewControllers:[DraftViewControllerProtocol] = []
    
    private var collectionView:UICollectionView!
    
    unowned let source: UIViewController
    
    init(source: UIViewController) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .OverFullScreen
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let frame = CGRectMake(0, 0, 100, 100)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: initialLayout)
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        let view = UIView(frame: frame)
        view.addSubview(collectionView)
        
        self.collectionView = collectionView
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
    
    func render(draftViewController:DraftViewControllerProtocol) -> UIView {
        guard let viewController = draftViewController as? UIViewController else { preconditionFailure() }
        addChildViewController(viewController)
        viewController.view.frame = view.bounds
        view.insertSubview(viewController.view, belowSubview: collectionView)
        
        defer {
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
        
        return viewController.view.snapshotViewAfterScreenUpdates(true)
    }
    
    var snapshots:[UIView]? = nil
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSnapshotsIfNeeded()
        dispatch_async(dispatch_get_main_queue()) { 
            self.collectionView.setCollectionViewLayout(self.normalLayout, animated: true)
        }
    }
    
    func loadSnapshotsIfNeeded() {
        guard snapshots == nil else { return }
        snapshots = [source.view.snapshotViewAfterScreenUpdates(false)] + selectableViewControllers.map(render)
        
        for indexPath in collectionView.indexPathsForVisibleItems() {
            (collectionView.cellForItemAtIndexPath(indexPath) as? OpenDraftCollectionViewCell)?.snapshotView = snapshots?[indexPath.item]
        }
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
        view.snapshotView = snapshots?[indexPath.item]
        
        if indexPath.item == 0 {
            view.showHeader = false
        } else {
            view.showHeader = true
            view.draftTitle = selectableViewControllers[indexPath.item - 1].draftTitle
        }
        
        return view
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView.collectionViewLayout != normalLayout {
            collectionView.setCollectionViewLayout(normalLayout, animated: true)
        } else if indexPath.item == 0 {
            collectionView.setCollectionViewLayout(initialLayout, animated: true)
        } else {
            draftSelectedLayout.selectedIndex = indexPath.item
            collectionView.setCollectionViewLayout(draftSelectedLayout, animated: true)
        }
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
            attributes.frame = CGRect(origin: CGPoint(x: 0, y: size.height - OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: count - 1)), size: size)
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

class DraftSelectedCollectionViewLayout: UICollectionViewLayout {
    
    private var selectedIndex = 1 { didSet { invalidateLayout() } }
    
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
        presenterAttributes.transform = DraftPresentationController.presenterTransform(width: size.width)
        
        var allAttributes = [presenterAttributes]
        
        for i in 1 ... selectedIndex {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            attributes.frame = UIEdgeInsetsInsetRect(CGRect(origin: CGPointZero, size: size), DraftPresentationController.presentedInsets)
            attributes.zIndex = i
            allAttributes.append(attributes)
        }
        
        for i in (selectedIndex + 1) ..< count {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            attributes.frame = CGRect(origin: CGPoint(x: 0, y: size.height), size: size)
            attributes.alpha = 0
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

class AllDraftsCollectionViewLayout : UICollectionViewLayout {
    
    private var allAttributes:[UICollectionViewLayoutAttributes] = []
    private var contentSize = CGSizeZero
    
    override func prepareLayout() {
        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections() == 1)
        
        let count = collectionView.numberOfItemsInSection(0)
        let size = collectionView.frame.size
        
        var topCenter = CGPoint(x: size.width / 2, y: 40)
        let scale = 1 - 12 / size.height
        
        let clampedCount = max(2, min(count, 5))
        let verticalGap = (size.height - 80) / CGFloat(clampedCount)
        let angleInDegrees:CGFloat = 61
        
        var allAttributes:[UICollectionViewLayoutAttributes] = []
        
        for i in 0 ..< count {
            
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            
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
        precondition(indexPath.section == 0)
        return allAttributes[indexPath.item]
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes[indexPath.item]
    }
}
