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
    
    weak var source: UIViewController?
    
    init(source: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .OverFullScreen
        self.transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let frame = CGRectMake(0, 0, 100, 100)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: initialLayout)
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
    }
    
    func render(draftViewController:DraftViewControllerProtocol) -> UIView {
        guard let viewController = draftViewController as? UIViewController else { preconditionFailure() }
        viewController.view.frame = UIEdgeInsetsInsetRect(view.bounds, DraftPresentationController.presentedInsets)
        viewController.view.layoutIfNeeded()
        return viewController.view.snapshotViewAfterScreenUpdates(true)
    }
    
    var snapshots:[UIView?]? = nil
    
    func loadSnapshotsIfNeeded() {
        guard snapshots == nil else { return }
        snapshots = [source?.view.snapshotViewAfterScreenUpdates(false)] + selectableViewControllers.map(render)
        
        for indexPath in collectionView.indexPathsForVisibleItems() {
            (collectionView.cellForItemAtIndexPath(indexPath) as? OpenDraftCollectionViewCell)?.snapshotView = snapshots?[indexPath.item]
        }
    }
    
    private func animateSwitchToLayout(layout:UICollectionViewLayout, parallelAnimation:(() -> Void)?, completion:(() -> Void)?) {
        
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
        
        if let parallelAnimation = parallelAnimation {
            needed += 1
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions(rawValue: 4), animations: parallelAnimation, completion: tryComplete)
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
            self.loadSnapshotsIfNeeded()
        })
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
        guard indexPath.item != 0 else {
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        guard let viewController = self.selectableViewControllers[indexPath.item - 1] as? UIViewController else { return }
        
        draftSelectedLayout.selectedIndex = indexPath.item
        animateSwitchToLayout(draftSelectedLayout, parallelAnimation: {
            self.forEachVisibleCell({ $0.showHeader = false })
        }, completion: {
            self.view.layer.speed = 1
            self.swapForViewController(viewController)
        })
    }
    
    // For I walk through the valley of the shadow of death...
    private func swapForViewController(viewController:UIViewController) {
        
        guard let presentingViewController = presentingViewController, let window = presentingViewController.view.window else { return }
        let snapshot = view.snapshotViewAfterScreenUpdates(true)
        window.addSubview(snapshot)
        
        presentingViewController.dismissViewControllerAnimated(false, completion: nil)
        presentingViewController.presentViewController(viewController, animated: false, completion: {
            dispatch_async(dispatch_get_main_queue(), {
                // FUCK FUCK FUCK FUCK FUCK WHY ISN'T ANYTHING WORKING CONSISTENTLY?
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
        toViewController.loadSnapshotsIfNeeded()
        
        toViewController.collectionView.collectionViewLayout = toViewController.initialLayout
        toViewController.collectionView.reloadData()
        toViewController.forEachVisibleCell({ $0.showCloseButton = false })
        
        toViewController.animateSwitchToLayout(toViewController.normalLayout, parallelAnimation: { 
            toViewController.forEachVisibleCell({ $0.showCloseButton = true })
        }, completion: {
            if transitionContext.transitionWasCancelled() {
                toView.removeFromSuperview()
                transitionContext.completeTransition(false)
            } else {
                transitionContext.completeTransition(true)
            }
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
        
        
        fromViewController.animateSwitchToLayout(fromViewController.initialLayout, parallelAnimation: { 
            fromViewController.forEachVisibleCell({ $0.showCloseButton = false })
        }, completion: {
            if transitionContext.transitionWasCancelled() {
                transitionContext.completeTransition(false)
            } else {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
        
        fromView.layer.speed = 0.75
        fromViewController.collectionView.setCollectionViewLayout(fromViewController.initialLayout, animated: true, completion: { _ in
            fromView.layer.speed = 1
        })
    }
}
