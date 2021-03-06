//
//  OpenDraftSelectorViewController.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class OpenDraftSelectorViewController: UIViewController {
    
    fileprivate let normalLayout = AllDraftsCollectionViewLayout()
    fileprivate let initialLayout: PresenterSelectedLayout
    fileprivate let draftSelectedLayout = DraftSelectedCollectionViewLayout()
    private let openDraftsIndicatorSource: OpenDraftsIndicatorSource
    private var selectableViewControllers: [UIViewController & DraftViewControllerProtocol] = []
    
    private var lastPanTimestamp: TimeInterval = 0
    
    fileprivate var collectionView: UICollectionView!
    
    weak var source: UIViewController?
    
    public init(openDraftsIndicatorSource: OpenDraftsIndicatorSource) {
        self.openDraftsIndicatorSource = openDraftsIndicatorSource
        self.initialLayout = PresenterSelectedLayout(openDraftsIndicatorSource: openDraftsIndicatorSource)
        super.init(nibName: nil, bundle: nil)
        self.restorationClass = OpenDraftSelectorViewController.self
        self.transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func loadView() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: normalLayout)
        collectionView.backgroundColor = .black
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.alwaysBounceVertical = true
        
        let view = UIView(frame: frame)
        view.addSubview(collectionView)
        
        self.collectionView = collectionView
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        OpenDraftCollectionViewCell.register(with: collectionView)
        selectableViewControllers = OpenDraftsManager.shared.openDraftingViewControllers
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        
        // Swiping the last item renders poorly in iOS8.  I don't care about fixing it.
        if #available(iOS 9, *) {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
            panGestureRecognizer.minimumNumberOfTouches = 1
            panGestureRecognizer.maximumNumberOfTouches = 1
            panGestureRecognizer.delegate = self
            collectionView.addGestureRecognizer(panGestureRecognizer)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationBecameActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadSnapshotsIfNeeded(animated: false)
    }
    
    @objc private func applicationBecameActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
            self.loadSnapshotsIfNeeded(animated: true)
        }
    }
    
    func render(_ draftViewController: DraftViewControllerProtocol) -> UIView {
        guard let viewController = draftViewController as? UIViewController else { preconditionFailure() }
        viewController.view.frame = UIEdgeInsetsInsetRect(view.bounds, DraftPresentationController.presentedInsets)
        viewController.view.layoutIfNeeded()
        if let snapshot = viewController.view.snapshotView(afterScreenUpdates: true) {
            return snapshot
        } else {
            let snapshot = UIView(frame: viewController.view.bounds)
            snapshot.backgroundColor = .white
            return snapshot
        }

    }
    
    var snapshots: [UIView?]? = nil
    
    func loadSnapshotsIfNeeded(animated: Bool) {
        guard self.snapshots == nil else { return }
        if source?.view.window == nil {
            source?.view.frame = view.frame
            source?.view.layoutIfNeeded()
        }
        let snapshots = [source?.view.snapshotView(afterScreenUpdates: true)] + selectableViewControllers.map(render)
        
        for indexPath in collectionView.indexPathsForVisibleItems {
            (collectionView.cellForItem(at: indexPath) as? OpenDraftCollectionViewCell)?.snapshotView = snapshots[indexPath.item]
        }
        
        if animated {
            let realSnapshots = snapshots.flatMap({$0})
            for snapshot in realSnapshots { snapshot.alpha = 0 }
            UIView.animate(withDuration: 0.25, animations: {
                for snapshot in realSnapshots { snapshot.alpha = 1 }
            }) 
        }
        
        if UIApplication.shared.applicationState == .active {
            self.snapshots = snapshots
        }
    }
    
    func reloadSourceSnapshot() {
        let snapshot = source?.view.snapshotView(afterScreenUpdates: true)
        (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? OpenDraftCollectionViewCell)?.snapshotView = snapshot
        
        if (snapshots?.count ?? 0) > 0 {
            snapshots?[0] = snapshot
        }
    }
    
    fileprivate func animateSwitchToLayout(_ layout: UICollectionViewLayout, almostParallelAnimation: (() -> Void)?, parallelAtEnd: Bool, completion: (() -> Void)?) {
        
        view.layer.speed = 0.75
        
        var needed = 1
        func tryComplete(_: Bool) {
            needed -= 1
            if needed == 0 {
                view.layer.speed = 1
                completion?()
            }
        }
        
        collectionView.setCollectionViewLayout(layout, animated: true, completion: tryComplete)
        
        if let almostParallelAnimation = almostParallelAnimation {
            needed += 1
            DispatchQueue.main.async(execute: { 
                UIView.animate(withDuration: 0.2, delay: parallelAtEnd ? 0.1 : 0, options: [], animations: almostParallelAnimation, completion: tryComplete)
            })
        }
    }
    
    fileprivate func forEachVisibleCell(_ block: (OpenDraftCollectionViewCell) -> Void) {
        for cell in collectionView.visibleCells {
            if let cell = cell as? OpenDraftCollectionViewCell {
                block(cell)
            }
        }
    }
    
    private var backgroundTransitionOriginalState: (size: CGSize, snapshots: [UIView?]?)?
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        // When iPad applications enter the background, they take a snapshot, rotate, take another snapshot, and rotate back.
        // For this very specific use case, we'll save the original snapshots so we can reuse them when we get back to the original state.
        if UIApplication.shared.applicationState == .background {
            
            if let originalState = backgroundTransitionOriginalState, originalState.size == size {
                backgroundTransitionOriginalState = nil
                snapshots = originalState.snapshots
                coordinator.animate(alongsideTransition: nil, completion: { context in
                    self.collectionView.reloadData()
                })
                return
            } else {
                backgroundTransitionOriginalState = (view.bounds.size, snapshots)
            }
        } else {
            backgroundTransitionOriginalState = nil
        }
        
        
        snapshots = nil
        forEachVisibleCell({ $0.snapshotView = nil })
        coordinator.animate(alongsideTransition: nil, completion: { context in
            self.loadSnapshotsIfNeeded(animated: true)
        })
    }
    
    private func removeViewController(at indexPath: IndexPath) {
        guard indexPath.item != 0 else { return }
        
        if selectableViewControllers.count > 1 {
            let removed = selectableViewControllers.remove(at: indexPath.item - 1)
            _ = snapshots?.remove(at: indexPath.item)
            collectionView.deleteItems(at: [indexPath])
            OpenDraftsManager.shared.remove(removed)
        } else {
            OpenDraftsManager.shared.remove(selectableViewControllers[0])
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func removeViewController(from cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        self.removeViewController(at: indexPath)
    }
}

extension OpenDraftSelectorViewController : UIGestureRecognizerDelegate {
    
    @objc func panned(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let now = Date.timeIntervalSinceReferenceDate
        
        switch gestureRecognizer.state {
        case .began:
            lastPanTimestamp = now
            if let indexPath = collectionView.indexPathForItem(at: gestureRecognizer.location(in: collectionView)) , indexPath.item != 0 {
                normalLayout.pannedItem = PannedItem(indexPath: indexPath, translation: gestureRecognizer.translation(in: collectionView))
            }
            
        case .changed:
            lastPanTimestamp = now
            normalLayout.pannedItem?.translation = gestureRecognizer.translation(in: collectionView)
            
        default:
            collectionView.performBatchUpdates({
                defer { self.normalLayout.pannedItem = nil }
                guard let pannedItem = self.normalLayout.pannedItem else { return }
                let delta = gestureRecognizer.translation(in: self.collectionView).x
                
                if delta < -(self.collectionView.frame.width / 2) || (delta < 0 && gestureRecognizer.velocity(in: self.collectionView).x < 0 && (now - self.lastPanTimestamp) < 0.25) {
                    self.normalLayout.deletingPannedItem = true
                    self.removeViewController(at: pannedItem.indexPath as IndexPath)
                }
            }, completion: { _ in
                self.normalLayout.deletingPannedItem = false
            })
        }
        
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard collectionView.collectionViewLayout == normalLayout else { return false }
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let velocity = gestureRecognizer.velocity(in: collectionView)
        guard abs(velocity.x) > abs(velocity.y) else { return false }
        guard let indexPath = collectionView.indexPathForItem(at: gestureRecognizer.location(in: collectionView)) , indexPath.item != 0 else { return false }
        
        return true
    }
}

extension OpenDraftSelectorViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + selectableViewControllers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != 0 else {
            presentingViewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let viewController = self.selectableViewControllers[indexPath.item - 1]
        
        draftSelectedLayout.selectedIndex = indexPath.item
        animateSwitchToLayout(draftSelectedLayout, almostParallelAnimation: {
            self.forEachVisibleCell({
                $0.showHeader = false
                $0.showGradientView = false
            })
        }, parallelAtEnd: false, completion: {
            self.swap(for: viewController)
        })
    }
    
    /**
     As elegant and clever as UIViewControllerAnimatedTransitioning is, going from A presents B to A presents C without showing A is the fucking worst.
     
     Something specific in iOS8+ triggers a rendering to occur between subsequent transitions so the best thing I've come up with is putting a snapshot of the view over the the whole window until the transition completes.
    */
    private func swap(for viewController: UIViewController) {
        
        guard let presentingViewController = presentingViewController, let window = view.window else { return }
        let snapshot = view.snapshotView(afterScreenUpdates: true)
        window.addSubview(snapshot!)
        
        presentingViewController.dismiss(animated: false, completion: nil)
        presentingViewController.present(viewController, animated: false, completion: {
            DispatchQueue.main.async(execute: {
                snapshot!.removeFromSuperview()
            })
        })
    }
}

extension OpenDraftSelectorViewController : UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return OpenDraftSelectorPresentationController()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return OpenDraftSelectorDismissalController()
    }
}

class OpenDraftSelectorPresentationController : NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let toViewController = transitionContext.viewController(forKey: .to) as! OpenDraftSelectorViewController
        let toView = transitionContext.view(forKey: .to)!
        
        let finalFrameRelativeToSuperview = transitionContext.finalFrame(for: toViewController)
        let finalFrame = toViewController.view.superview?.convert(finalFrameRelativeToSuperview, to: toView.superview) ?? finalFrameRelativeToSuperview
        
        transitionContext.containerView.addSubview(toView)
        toView.frame = finalFrame
        toView.layoutIfNeeded()
        toViewController.source = transitionContext.viewController(forKey: .from)
        toViewController.loadSnapshotsIfNeeded(animated: false)
        
        toViewController.collectionView.collectionViewLayout = toViewController.initialLayout
        toViewController.collectionView.reloadData()
        
        toViewController.animateSwitchToLayout(toViewController.normalLayout, almostParallelAnimation: {
            toViewController.forEachVisibleCell({
                $0.showCloseButton = true
                $0.showGradientView = true
            })
        }, parallelAtEnd: true, completion: {
            if transitionContext.transitionWasCancelled {
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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController = transitionContext.viewController(forKey: .from) as! OpenDraftSelectorViewController
        let fromView = transitionContext.view(forKey: .from)!
        let toViewController = transitionContext.viewController(forKey: .to)!
        
        let initialFrameRelativeToSuperview = transitionContext.initialFrame(for: fromViewController)
        let initialFrame = fromViewController.view.superview?.convert(initialFrameRelativeToSuperview, to: fromView.superview) ?? initialFrameRelativeToSuperview
        
        let finalFrameForPresenter = transitionContext.finalFrame(for: toViewController)
        
        transitionContext.containerView.addSubview(fromView)
        fromView.frame = initialFrame
        fromView.layoutIfNeeded()
        
        if !finalFrameForPresenter.isEmpty {
            toViewController.view.frame = finalFrameForPresenter
            toViewController.view.layoutIfNeeded()
        }
        
        fromViewController.reloadSourceSnapshot()
        
        fromViewController.animateSwitchToLayout(fromViewController.initialLayout, almostParallelAnimation: {
            fromViewController.forEachVisibleCell({
                $0.showCloseButton = false
                $0.showGradientView = false
            })
        }, parallelAtEnd: false, completion: {
            if transitionContext.transitionWasCancelled {
                transitionContext.completeTransition(false)
            } else {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
    }
}

extension OpenDraftSelectorViewController : UIViewControllerRestoration {
    
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        
        guard let openDraftsIndicatorSource = coder.decodeObject(forKey: "openDraftsIndicatorSource") as? OpenDraftsIndicatorSource else { return nil }
        
        let viewController = OpenDraftSelectorViewController(openDraftsIndicatorSource: openDraftsIndicatorSource)
        viewController.restorationIdentifier = identifierComponents.last as? String
        return viewController
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(source, forKey: "source")
        coder.encodeSafeArray(selectableViewControllers, forKey: "selectableViewControllers")
        coder.encode(openDraftsIndicatorSource, forKey: "openDraftsIndicatorSource")
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        source = coder.decodeObject(forKey: "source") as? UIViewController
        selectableViewControllers = coder.decodeSafeArrayForKey("selectableViewControllers")
        collectionView.reloadData()
        super.decodeRestorableState(with: coder)
    }
    
    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }
}

extension UIViewController {
    
    @nonobjc var hasRestorationSource: Bool {
        return restorationClass != nil || storyboard != nil
    }
    
    @nonobjc var isRestorationEligible: Bool {
        return hasRestorationSource && restorationIdentifier != nil
    }
    
    @nonobjc func setRestorationIdentifier(_ restorationIdentifier: String, contingentOnViewController previousViewController: UIViewController) {
        if previousViewController.isRestorationEligible && hasRestorationSource {
            self.restorationIdentifier = restorationIdentifier
        } else {
            self.restorationIdentifier = nil
        }
    }
}
