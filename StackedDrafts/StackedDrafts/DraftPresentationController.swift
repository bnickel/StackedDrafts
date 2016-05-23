//
//  DraftPresentationController.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

@objc(SEUIDraftViewControllerProtocol) public protocol DraftViewControllerProtocol : NSObjectProtocol {
    var draggableView:UIView? { get }
    var draftTitle:String? { get }
}

@objc(SEUIDraftPresentationController) public class DraftPresentationController : UIPresentationController {
    
    enum notifications : String {
        case didPresentDraftViewController = "DraftPresentationController.notifications.didPresentDraftViewController"
        case willDismissNonInteractiveDraftViewController = "DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController"
        
        enum keys : String {
            case viewController
        }
    }
    
    public var shouldMinimize:Bool = false
    var interactiveTransitioning:UIPercentDrivenInteractiveTransition? = nil
    private lazy var interactiveDismissalGestureRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    private var lastInteractionTimestamp:NSTimeInterval = 0
    
    private let wrappingView = UIView()
    private let accessibilityDismissalView = AccessibilityDismissalView()
    private lazy var headerOverlayView = OpenDraftHeaderOverlayView()
    private var simulatedPresentingView:UIView?
    
    var hasBeenPresented = false
    
    public override func presentedView() -> UIView? {
        return wrappingView
    }
    
    public override func frameOfPresentedViewInContainerView() -> CGRect {
        let frame = super.frameOfPresentedViewInContainerView()
        return UIEdgeInsetsInsetRect(frame, DraftPresentationController.presentedInsets)
    }
    
    public override func presentationTransitionWillBegin() {
        shouldMinimize = false
        configureViews()
        addPresentationOverlayAnimations()
        addAccessibilityDismissView()
    }
    
    public override func dismissalTransitionWillBegin() {
        notifyThatDismissalWillBeginIfNonInteractive()
        removeSimulatedPresentingView()
        addDismissalOverlayAnimations()
    }
    
    public override func presentationTransitionDidEnd(completed: Bool) {
        attachInteractiveDismissalGestureRecognizer()
        addSimulatedPresentingViewIfPresented(completed)
        notifyThatPresentationDidEndIfCompleted(completed)
        if completed { hasBeenPresented = true }
    }
    
    public override func dismissalTransitionDidEnd(completed: Bool) {
        addSimulatedPresentingViewIfPresented(!completed)
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        layoutSimulatedPresentingView()
        self.presentedView()?.frame = frameOfPresentedViewInContainerView()
    }
    
    public override func shouldRemovePresentersView() -> Bool {
        return DraftPresentationController.isPhone
    }
    
    private static let isPhone = UIDevice.currentDevice().userInterfaceIdiom == .Phone
    
    class var presentedInsets:UIEdgeInsets {
        let application = UIApplication.sharedApplication()
        let statusBarHeight = application.statusBarHidden ? 0 : application.statusBarFrame.height
        let topInset:CGFloat
        
        if isPhone {
            topInset = 20 + statusBarHeight
        } else {
            topInset = 22 + statusBarHeight
        }
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    class func presenterTransform(height height:CGFloat) -> CGAffineTransform {
        if isPhone {
            let topInset = presentedInsets.top
            let heightReduction = 2 * topInset * 0.75
            let scale = (height - heightReduction) / height
            return CGAffineTransformMakeScale(scale, scale)
        } else {
            return CGAffineTransformIdentity
        }
    }
}

public extension UIViewController {
    @objc(SEUI_draftPresentationController) var draftPresentationController:DraftPresentationController? {
        return presentationController as? DraftPresentationController
    }
}

// MARK: - Simulated presenting view
private extension DraftPresentationController {
    
    func addSimulatedPresentingViewIfPresented(presented:Bool) {
        removeSimulatedPresentingView()
        
        guard shouldRemovePresentersView() else { return }
        guard let containerView = containerView where presented else { return }
        guard let delegate = presentedViewController.transitioningDelegate as? DraftTransitioningDelegate else { return }
        
        let simulatedPresentingView = delegate.simulatedPresentingView(for: presentingViewController)
        
        containerView.insertSubview(simulatedPresentingView, atIndex: 0)
        self.simulatedPresentingView = simulatedPresentingView
        layoutSimulatedPresentingView()
    }
    
    func removeSimulatedPresentingView() {
        simulatedPresentingView?.removeFromSuperview()
    }
    
    func layoutSimulatedPresentingView() {
        guard let containerView = containerView, let simulatedPresentingView = simulatedPresentingView else { return }
        let bounds = containerView.bounds
        simulatedPresentingView.bounds = bounds
        simulatedPresentingView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        simulatedPresentingView.transform = self.dynamicType.presenterTransform(height: bounds.height)
    }
}

// MARK: - Notifications
private extension DraftPresentationController {
    
    func notifyThatDismissalWillBeginIfNonInteractive() {
        guard !shouldMinimize else { return }
        postNotification(notifications.willDismissNonInteractiveDraftViewController)
    }
    
    func notifyThatPresentationDidEndIfCompleted(completed: Bool) {
        guard completed else { return }
        postNotification(notifications.didPresentDraftViewController)
    }
    
    func postNotification(notification: notifications) {
        NSNotificationCenter.defaultCenter().postNotificationName(notification.rawValue, object: self, userInfo: [notifications.keys.viewController.rawValue: presentedViewController])
    }
}

// MARK: - Interactivity
extension DraftPresentationController {
    
    private func attachInteractiveDismissalGestureRecognizer() {
        guard interactiveDismissalGestureRecognizer.view == nil else { return }
        
        if let presentedViewController = presentedViewController as? DraftViewControllerProtocol {
            presentedViewController.draggableView?.addGestureRecognizer(interactiveDismissalGestureRecognizer)
        } else if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.navigationBar.addGestureRecognizer(interactiveDismissalGestureRecognizer)
        }
    }
    
    @objc private func panned(sender : UIPanGestureRecognizer) {
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        
        switch sender.state {
        case .Began:
            lastInteractionTimestamp = now
            shouldMinimize = true
            interactiveTransitioning = UIPercentDrivenInteractiveTransition()
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            lastInteractionTimestamp = now
            interactiveTransitioning?.updateInteractiveTransition(min(sender.translationInView(containerView).y / (presentedViewController.view.bounds.height - dismissalInset), 1))
        case .Cancelled:
            interactiveTransitioning?.completionSpeed = DraftDismissalAnimatedTransitioning.interactiveCompletionSpeed
            interactiveTransitioning?.cancelInteractiveTransition()
            interactiveTransitioning = nil
        case .Ended:
            interactiveTransitioning?.completionCurve = .EaseOut
            interactiveTransitioning?.completionSpeed = DraftDismissalAnimatedTransitioning.interactiveCompletionSpeed
            if sender.velocityInView(containerView).y > 0 && (now - lastInteractionTimestamp) < 0.25 {
                interactiveTransitioning?.finishInteractiveTransition()
            } else {
                interactiveTransitioning?.cancelInteractiveTransition()
            }
            interactiveTransitioning = nil
        default:
            break
        }
    }
    
    var presentationInset:CGFloat {
        guard hasBeenPresented && presentedViewController is DraftViewControllerProtocol else { return 0 }
        return OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: OpenDraftsManager.sharedInstance.openDraftingViewControllers.count)
    }
    
    var dismissalInset:CGFloat {
        guard shouldMinimize && presentedViewController is DraftViewControllerProtocol else { return 0 }
        return OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: OpenDraftsManager.sharedInstance.openDraftingViewControllers.count)
    }
}

// MARK: - Views

private extension DraftPresentationController {
    
    class AccessibilityDismissalView : UIView {
        weak var presentationController:DraftPresentationController?
        
        private override func accessibilityActivate() -> Bool {
            guard let presentationController = presentationController else { return false }
            presentationController.shouldMinimize = true
            presentationController.presentingViewController.dismissViewControllerAnimated(true, completion: nil)
            return true
        }
    }
    
    func configureViews() {
        wrappingView.frame = presentedViewController.view.frame
        wrappingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        wrappingView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = wrappingView.bounds
        
        accessibilityDismissalView.accessibilityTraits = UIAccessibilityTraitButton
        accessibilityDismissalView.accessibilityLabel = NSLocalizedString("Minimize draft", comment: "Accessibility")
        accessibilityDismissalView.isAccessibilityElement = true
        accessibilityDismissalView.presentationController = self
    }
    
    func addHeaderOverlayIfNeeded() {
        guard let draftViewController = presentedViewController as? DraftViewControllerProtocol where hasBeenPresented else { return }
        var frame = wrappingView.bounds
        frame.size.height = 44
        
        headerOverlayView.labelText = draftViewController.draftTitle
        headerOverlayView.frame = frame
        headerOverlayView.translatesAutoresizingMaskIntoConstraints = true
        headerOverlayView.autoresizingMask = [.FlexibleWidth, .FlexibleBottomMargin]
        wrappingView.addSubview(headerOverlayView)
    }
    
    func addAccessibilityDismissView() {
        var frame = frameOfPresentedViewInContainerView()
        frame.origin.y -= 20
        frame.size.height = 20
        
        accessibilityDismissalView.frame = frame
        containerView?.addSubview(accessibilityDismissalView)
    }
    
    func addPresentationOverlayAnimations() {
        addHeaderOverlayIfNeeded()
        
        headerOverlayView.extraSpecialAlpha = 1
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ context in
            self.headerOverlayView.extraSpecialAlpha = 0
        }, completion: { context in
            self.headerOverlayView.removeFromSuperview()
        })
    }
    
    func addDismissalOverlayAnimations() {
        
        if shouldMinimize {
            addHeaderOverlayIfNeeded()
        }
        
        headerOverlayView.extraSpecialAlpha = 0
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ context in
            self.headerOverlayView.extraSpecialAlpha = 1
        }, completion: { context in
            self.headerOverlayView.removeFromSuperview()
        })
    }
}
