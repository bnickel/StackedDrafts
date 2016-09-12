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

@objc(SEUIDraftPresentationController) open class DraftPresentationController : UIPresentationController {
    
    enum notifications {
        static let didPresentDraftViewController = Notification.Name(rawValue: "DraftPresentationController.notifications.didPresentDraftViewController")
        static let willDismissNonInteractiveDraftViewController = Notification.Name(rawValue: "DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController")
        
        enum keys {
            static let viewController = "viewController"
        }
    }
    
    open var shouldMinimize:Bool = false
    var interactiveTransitioning:UIPercentDrivenInteractiveTransition? = nil
    fileprivate lazy var interactiveDismissalGestureRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    fileprivate var lastInteractionTimestamp:TimeInterval = 0
    
    fileprivate let wrappingView = UIView()
    fileprivate let accessibilityDismissalView = AccessibilityDismissalView()
    fileprivate lazy var headerOverlayView = OpenDraftHeaderOverlayView()
    fileprivate var simulatedPresentingView:UIView?
    
    var hasBeenPresented = false
    
    open override var presentedView : UIView? {
        return wrappingView
    }
    
    open override var frameOfPresentedViewInContainerView : CGRect {
        let frame = super.frameOfPresentedViewInContainerView
        return UIEdgeInsetsInsetRect(frame, DraftPresentationController.presentedInsets)
    }
    
    open override func presentationTransitionWillBegin() {
        shouldMinimize = false
        configureViews()
        addPresentationOverlayAnimations()
        addPresentationAlphaAnimations()
        addAccessibilityDismissView()
    }
    
    open override func dismissalTransitionWillBegin() {
        notifyThatDismissalWillBeginIfNonInteractive()
        removeSimulatedPresentingView()
        addDismissalOverlayAnimations()
        addDismissalAlphaAnimations()
    }
    
    open override func presentationTransitionDidEnd(_ completed: Bool) {
        attachInteractiveDismissalGestureRecognizer()
        addSimulatedPresentingViewIfPresented(completed)
        notifyThatPresentationDidEndIfCompleted(completed)
        if completed { hasBeenPresented = true }
    }
    
    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        if !completed { shouldMinimize = false }
        addSimulatedPresentingViewIfPresented(!completed)
    }
    
    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        layoutSimulatedPresentingView()
        self.presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    open override var shouldRemovePresentersView : Bool {
        return DraftPresentationController.isPhone
    }
    
    fileprivate static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    
    class var presentedInsets:UIEdgeInsets {
        let application = UIApplication.shared
        let statusBarHeight = application.isStatusBarHidden ? 0 : application.statusBarFrame.height
        let topInset:CGFloat
        
        if isPhone {
            topInset = 20 + statusBarHeight
        } else {
            topInset = 22 + statusBarHeight
        }
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    class func presenterTransform(height:CGFloat) -> CGAffineTransform {
        if isPhone {
            let topInset = presentedInsets.top
            let heightReduction = 2 * topInset * 0.75
            let scale = (height - heightReduction) / height
            return CGAffineTransform(scaleX: scale, y: scale)
        } else {
            return .identity
        }
    }
    
    class var presenterAlpha:CGFloat { return 0.7 }
}

public extension UIViewController {
    @objc(SEUI_draftPresentationController) var draftPresentationController:DraftPresentationController? {
        return presentationController as? DraftPresentationController
    }
}

// MARK: - Simulated presenting view
private extension DraftPresentationController {
    
    func addSimulatedPresentingViewIfPresented(_ presented:Bool) {
        removeSimulatedPresentingView()
        
        guard shouldRemovePresentersView else { return }
        guard let containerView = containerView , presented else { return }
        guard let delegate = presentedViewController.transitioningDelegate as? DraftTransitioningDelegate else { return }
        
        let simulatedPresentingView = delegate.simulatedPresentingView(for: presentingViewController)
        
        containerView.insertSubview(simulatedPresentingView, at: 0)
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
        simulatedPresentingView.transform = type(of: self).presenterTransform(height: bounds.height)
        simulatedPresentingView.alpha = type(of: self).presenterAlpha
    }
}

// MARK: - Notifications
private extension DraftPresentationController {
    
    func notifyThatDismissalWillBeginIfNonInteractive() {
        guard !shouldMinimize else { return }
        postNotification(notifications.willDismissNonInteractiveDraftViewController)
    }
    
    func notifyThatPresentationDidEndIfCompleted(_ completed: Bool) {
        guard completed else { return }
        postNotification(notifications.didPresentDraftViewController)
    }
    
    func postNotification(_ notification: NSNotification.Name) {
        NotificationCenter.default.post(name: notification, object: self, userInfo: [notifications.keys.viewController: presentedViewController])
    }
}

// MARK: - Interactivity
extension DraftPresentationController {
    
    fileprivate func attachInteractiveDismissalGestureRecognizer() {
        guard interactiveDismissalGestureRecognizer.view == nil else { return }
        
        if let presentedViewController = presentedViewController as? DraftViewControllerProtocol {
            presentedViewController.draggableView?.addGestureRecognizer(interactiveDismissalGestureRecognizer)
        } else if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.navigationBar.addGestureRecognizer(interactiveDismissalGestureRecognizer)
        }
    }
    
    @objc fileprivate func panned(_ sender : UIPanGestureRecognizer) {
        
        let now = Date.timeIntervalSinceReferenceDate
        
        switch sender.state {
        case .began:
            lastInteractionTimestamp = now
            shouldMinimize = true
            interactiveTransitioning = UIPercentDrivenInteractiveTransition()
            UIView.performWithoutAnimation({ 
                self.presentedViewController.view.endEditing(true)
            })
            presentingViewController.dismiss(animated: true, completion: nil)
        case .changed:
            lastInteractionTimestamp = now
            interactiveTransitioning?.update(min(sender.translation(in: containerView).y / (presentedViewController.view.bounds.height - dismissalInset), 1))
        case .cancelled:
            interactiveTransitioning?.completionSpeed = DraftDismissalAnimatedTransitioning.interactiveCompletionSpeed
            interactiveTransitioning?.cancel()
            interactiveTransitioning = nil
        case .ended:
            interactiveTransitioning?.completionCurve = .easeOut
            interactiveTransitioning?.completionSpeed = DraftDismissalAnimatedTransitioning.interactiveCompletionSpeed
            if sender.velocity(in: containerView).y > 0 && (now - lastInteractionTimestamp) < 0.25 {
                interactiveTransitioning?.finish()
            } else {
                interactiveTransitioning?.cancel()
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

// MARK: - Alpha

private extension DraftPresentationController {
    
    func addPresentationAlphaAnimations() {
        addAlphaAnimations(initial: 1, final: type(of: self).presenterAlpha)
    }
    
    func addDismissalAlphaAnimations() {
        addAlphaAnimations(initial: type(of: self).presenterAlpha, final: 1)
    }
    
    func addAlphaAnimations(initial initialAlpha:CGFloat, final finalAlpha:CGFloat) {
        let view = presentingViewController.view
        view?.alpha = initialAlpha
        presentingViewController.transitionCoordinator?.animateAlongsideTransition(in: view, animation: { context in
            view?.alpha = finalAlpha
        }, completion: nil)
    }
}

// MARK: - Views

private extension DraftPresentationController {
    
    class AccessibilityDismissalView : UIView {
        weak var presentationController:DraftPresentationController?
        
        fileprivate override func accessibilityActivate() -> Bool {
            guard let presentationController = presentationController else { return false }
            presentationController.shouldMinimize = true
            presentationController.presentingViewController.dismiss(animated: true, completion: nil)
            return true
        }
    }
    
    func configureViews() {
        wrappingView.frame = presentedViewController.view.frame
        wrappingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrappingView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = wrappingView.bounds
        
        accessibilityDismissalView.accessibilityTraits = UIAccessibilityTraitButton
        accessibilityDismissalView.accessibilityLabel = NSLocalizedString("Minimize draft", comment: "Accessibility")
        accessibilityDismissalView.isAccessibilityElement = true
        accessibilityDismissalView.presentationController = self
    }
    
    func addHeaderOverlayIfNeeded() {
        guard let draftViewController = presentedViewController as? DraftViewControllerProtocol , hasBeenPresented else { return }
        var frame = wrappingView.bounds
        frame.size.height = 44
        
        headerOverlayView.labelText = draftViewController.draftTitle
        headerOverlayView.frame = frame
        headerOverlayView.translatesAutoresizingMaskIntoConstraints = true
        headerOverlayView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        wrappingView.addSubview(headerOverlayView)
    }
    
    func addAccessibilityDismissView() {
        var frame = frameOfPresentedViewInContainerView
        frame.origin.y -= 20
        frame.size.height = 20
        
        accessibilityDismissalView.frame = frame
        containerView?.addSubview(accessibilityDismissalView)
    }
    
    func addPresentationOverlayAnimations() {
        addHeaderOverlayIfNeeded()
        
        headerOverlayView.extraSpecialAlpha = 1
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
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
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.headerOverlayView.extraSpecialAlpha = 1
        }, completion: { context in
            self.headerOverlayView.removeFromSuperview()
        })
    }
}
