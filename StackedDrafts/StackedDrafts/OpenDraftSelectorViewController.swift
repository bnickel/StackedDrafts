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
    
    private var lastPanTimestamp:NSTimeInterval = 0
    
    private var collectionView:UICollectionView!
    
    weak var source: UIViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.restorationClass = OpenDraftSelectorViewController.self
        self.transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func loadView() {
        let frame = CGRectMake(0, 0, 100, 100)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: normalLayout)
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        collectionView.alwaysBounceVertical = true
        
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
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.delegate = self
        collectionView.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSnapshotsIfNeeded(animated: false)
    }
    
    func render(draftViewController:DraftViewControllerProtocol) -> UIView {
        guard let viewController = draftViewController as? UIViewController else { preconditionFailure() }
        viewController.view.frame = UIEdgeInsetsInsetRect(view.bounds, DraftPresentationController.presentedInsets)
        viewController.view.layoutIfNeeded()
        return viewController.view.snapshotViewAfterScreenUpdates(true)
    }
    
    var snapshots:[UIView?]? = nil
    
    func loadSnapshotsIfNeeded(animated animated:Bool) {
        guard snapshots == nil else { return }
        snapshots = [source?.view.snapshotViewAfterScreenUpdates(true)] + selectableViewControllers.map(render)
        
        for indexPath in collectionView.indexPathsForVisibleItems() {
            (collectionView.cellForItemAtIndexPath(indexPath) as? OpenDraftCollectionViewCell)?.snapshotView = snapshots?[indexPath.item]
        }
        
        if animated {
            let realSnapshots = snapshots?.flatMap({$0}) ?? []
            for snapshot in realSnapshots { snapshot.alpha = 0 }
            UIView.animateWithDuration(0.25) {
                for snapshot in realSnapshots { snapshot.alpha = 1 }
            }
        }
    }
    
    func reloadSourceSnapshot() {
        let snapshot = source?.view.snapshotViewAfterScreenUpdates(true)
        (collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? OpenDraftCollectionViewCell)?.snapshotView = snapshot
        
        if snapshots?.count > 0 {
            snapshots?[0] = snapshot
        }
    }
    
    private func animateSwitchToLayout(layout:UICollectionViewLayout, almostParallelAnimation:(() -> Void)?, parallelAtEnd:Bool, completion:(() -> Void)?) {
        
        view.layer.speed = 0.75
        
        var needed = 1
        func tryComplete(_:Bool) {
            needed -= 1
            if needed == 0 {
                view.layer.speed = 1
                completion?()
            }
        }
        
        collectionView.setCollectionViewLayout(layout, animated: true, completion: tryComplete)
        
        if let almostParallelAnimation = almostParallelAnimation {
            needed += 1
            dispatch_async(dispatch_get_main_queue(), { 
                UIView.animateWithDuration(0.2, delay: parallelAtEnd ? 0.1 : 0, options: [], animations: almostParallelAnimation, completion: tryComplete)
            })
        }
    }
    
    private func forEachVisibleCell(@noescape block: (OpenDraftCollectionViewCell) -> Void) {
        for cell in collectionView.visibleCells() {
            if let cell = cell as? OpenDraftCollectionViewCell {
                block(cell)
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        snapshots = nil
        forEachVisibleCell({ $0.snapshotView = nil })
        coordinator.animateAlongsideTransition(nil, completion: { context in
            self.loadSnapshotsIfNeeded(animated: true)
        })
    }
    
    private func removeViewController(at indexPath:NSIndexPath) {
        guard indexPath.item != 0 else { return }
        
        if selectableViewControllers.count > 1 {
            let removed = selectableViewControllers.removeAtIndex(indexPath.item - 1)
            snapshots?.removeAtIndex(indexPath.item)
            collectionView.deleteItemsAtIndexPaths([indexPath])
            OpenDraftsManager.sharedInstance.remove(removed)
        } else {
            OpenDraftsManager.sharedInstance.remove(selectableViewControllers[0])
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    private func removeViewController(from cell:UICollectionViewCell) {
        guard let indexPath = collectionView.indexPathForCell(cell) else { return }
        self.removeViewController(at:indexPath)
    }
}

extension OpenDraftSelectorViewController : UIGestureRecognizerDelegate {
    
    @objc func panned(gestureRecognizer: UIPanGestureRecognizer) {
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        
        switch gestureRecognizer.state {
        case .Began:
            lastPanTimestamp = now
            if let indexPath = collectionView.indexPathForItemAtPoint(gestureRecognizer.locationInView(collectionView)) where indexPath.item != 0 {
                normalLayout.pannedItem = PannedItem(indexPath: indexPath, translation: gestureRecognizer.translationInView(collectionView))
            }
            
        case .Changed:
            lastPanTimestamp = now
            normalLayout.pannedItem?.translation = gestureRecognizer.translationInView(collectionView)
            
        default:
            collectionView.performBatchUpdates({
                defer { self.normalLayout.pannedItem = nil }
                guard let pannedItem = self.normalLayout.pannedItem else { return }
                let delta = gestureRecognizer.translationInView(self.collectionView).x
                
                if delta < -(self.collectionView.frame.width / 2) || (delta < 0 && gestureRecognizer.velocityInView(self.collectionView).x < 0 && (now - self.lastPanTimestamp) < 0.25) {
                    self.normalLayout.deletingPannedItem = true
                    self.removeViewController(at: pannedItem.indexPath)
                }
            }, completion: { _ in
                self.normalLayout.deletingPannedItem = false
            })
        }
        
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard collectionView.collectionViewLayout == normalLayout else { return false }
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let velocity = gestureRecognizer.velocityInView(collectionView)
        guard abs(velocity.x) > abs(velocity.y) else { return false }
        guard let indexPath = collectionView.indexPathForItemAtPoint(gestureRecognizer.locationInView(collectionView)) where indexPath.item != 0 else { return false }
        
        return true
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
        
        view.closeTapped = removeViewController(from:)
        
        return view
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.item != 0 else {
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        guard let viewController = self.selectableViewControllers[indexPath.item - 1] as? UIViewController else { return }
        
        draftSelectedLayout.selectedIndex = indexPath.item
        animateSwitchToLayout(draftSelectedLayout, almostParallelAnimation: {
            self.forEachVisibleCell({
                $0.showHeader = false
                $0.showGradientView = false
            })
        }, parallelAtEnd: false, completion: {
            self.swapForViewController(viewController)
        })
    }
    
    /**
     As elegant and clever as UIViewControllerAnimatedTransitioning is, going from A presents B to A presents C without showing A is the fucking worst.
     
     Something specific in iOS8+ triggers a rendering to occur between subsequent transitions so the best thing I've come up with is putting a snapshot of the view over the the whole window until the transition completes.
    */
    private func swapForViewController(viewController:UIViewController) {
        
        guard let presentingViewController = presentingViewController, let window = view.window else { return }
        let snapshot = view.snapshotViewAfterScreenUpdates(true)
        window.addSubview(snapshot)
        
        presentingViewController.dismissViewControllerAnimated(false, completion: nil)
        presentingViewController.presentViewController(viewController, animated: false, completion: {
            dispatch_async(dispatch_get_main_queue(), {
                snapshot.removeFromSuperview()
            })
        })
    }
}

extension OpenDraftSelectorViewController : UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return OpenDraftSelectorPresentationController()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return OpenDraftSelectorDismissalController()
    }
}

class OpenDraftSelectorPresentationController : NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(transitionContext)
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! OpenDraftSelectorViewController
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let collectionView = toViewController.collectionView
        
        let finalFrameRelativeToSuperview = transitionContext.finalFrameForViewController(toViewController)
        let finalFrame = toViewController.view.superview?.convertRect(finalFrameRelativeToSuperview, toView: toView.superview) ?? finalFrameRelativeToSuperview
        
        transitionContext.containerView()?.addSubview(toView)
        toView.frame = finalFrame
        toView.layoutIfNeeded()
        toViewController.source = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        toViewController.loadSnapshotsIfNeeded(animated: false)
        
        toViewController.collectionView.collectionViewLayout = toViewController.initialLayout
        toViewController.collectionView.reloadData()
        
        toViewController.animateSwitchToLayout(toViewController.normalLayout, almostParallelAnimation: {
            toViewController.forEachVisibleCell({
                $0.showCloseButton = true
                $0.showGradientView = true
            })
        }, parallelAtEnd: true, completion: {
            if transitionContext.transitionWasCancelled() {
                toView.removeFromSuperview()
                transitionContext.completeTransition(false)
            } else {
                transitionContext.completeTransition(true)
            }
        })
        
        toViewController.forEachVisibleCell({
            $0.showCloseButton = false
            $0.showGradientView = false
        })
    }
}

class OpenDraftSelectorDismissalController : NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(transitionContext)
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! OpenDraftSelectorViewController
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        let initialFrameRelativeToSuperview = transitionContext.initialFrameForViewController(fromViewController)
        let initialFrame = fromViewController.view.superview?.convertRect(initialFrameRelativeToSuperview, toView: fromView.superview) ?? initialFrameRelativeToSuperview
        
        transitionContext.containerView()?.addSubview(fromView)
        fromView.frame = initialFrame
        fromView.layoutIfNeeded()
        
        fromViewController.reloadSourceSnapshot()
        
        
        fromViewController.animateSwitchToLayout(fromViewController.initialLayout, almostParallelAnimation: {
            fromViewController.forEachVisibleCell({
                $0.showCloseButton = false
                $0.showGradientView = false
            })
        }, parallelAtEnd: false, completion: {
            if transitionContext.transitionWasCancelled() {
                transitionContext.completeTransition(false)
            } else {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
    }
}

extension OpenDraftSelectorViewController : UIViewControllerRestoration {
    
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        let viewController = OpenDraftSelectorViewController()
        viewController.restorationIdentifier = identifierComponents.last as? String
        return viewController
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(source, forKey: "source")
        coder.encodeSafeArray(selectableViewControllers, forKey: "selectableViewControllers")
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        source = coder.decodeObjectForKey("source") as? UIViewController
        selectableViewControllers = coder.decodeSafeArrayForKey("selectableViewControllers")
        collectionView.reloadData()
        super.decodeRestorableStateWithCoder(coder)
    }
    
    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }
}

extension UIViewController {
    
    var hasRestorationSource:Bool {
        return restorationClass != nil || storyboard != nil
    }
    
    var isRestorationEligible:Bool {
        return hasRestorationSource && restorationIdentifier != nil
    }
    
    func setRestorationIdentifier(restorationIdentifier:String, contingentOnViewController previousViewController:UIViewController) {
        if previousViewController.isRestorationEligible && hasRestorationSource {
            self.restorationIdentifier = restorationIdentifier
        } else {
            self.restorationIdentifier = nil
        }
    }
}
