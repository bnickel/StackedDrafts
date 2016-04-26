//
//  DraftPresentationController.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

public protocol DraftViewControllerProtocol : NSObjectProtocol {
    var draggableView:UIView? { get }
    var draftTitle:String? { get }
}

class DraftPresentationController : UIPresentationController {
    
    enum notifications : String {
        case didPresentDraftViewController = "DraftPresentationController.notifications.didPresentDraftViewController"
        case willDismissNonInteractiveDraftViewController = "DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController"
        
        enum keys : String {
            case viewController
        }
    }
    
    var interactiveTransitioning:UIPercentDrivenInteractiveTransition? = nil
    private lazy var interactiveDismissalGestureRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    private var lastInteractionTimestamp:NSTimeInterval = 0
    
    private let wrappingView = UIView()
    private lazy var headerOverlayView = OpenDraftHeaderOverlayView()
    var hasBeenPresented = false
    
    override func presentedView() -> UIView? {
        return wrappingView
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        let frame = super.frameOfPresentedViewInContainerView()
        return UIEdgeInsetsInsetRect(frame, DraftPresentationController.presentedInsets)
    }
    
    override func presentationTransitionWillBegin() {
        configureViews()
        addPresentationScalingAnimation()
        addPresentationOverlayAnimations()
    }
    
    override func dismissalTransitionWillBegin() {
        notifyThatDismissalWillBeginIfNonInteractive()
        addDismissalScalingAnimation()
        addDismissalOverlayAnimations()
    }
    
    override func presentationTransitionDidEnd(completed: Bool) {
        attachInteractiveDismissalGestureRecognizer()
        notifyThatPresentationDidEndIfCompleted(completed)
        if completed { hasBeenPresented = true }
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        fixPresentingViewControllerBounds()
    }
    
    static let presentedInsets = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
    
    class func presenterTransform(width width:CGFloat) -> CGAffineTransform {
        let scale = (width - 30) / width
        return CGAffineTransformMakeScale(scale, scale)
    }
}

extension UIViewController {
    var draftPresentationController:DraftPresentationController? {
        return presentationController as? DraftPresentationController
    }
}

// MARK: - Scaling
private extension DraftPresentationController {
    
    func setScale(expanded expanded: Bool) {
        if expanded {
            presentingViewController.view.transform = DraftPresentationController.presenterTransform(width: presentingViewController.view.bounds.width)
        } else {
            presentingViewController.view.transform = CGAffineTransformIdentity
        }
    }
    
    func addPresentationScalingAnimation() {
        presentingViewController.transitionCoordinator()?.animateAlongsideTransitionInView(containerView!, animation: { context in
            self.setScale(expanded: true)
            }, completion: { context in
                self.setScale(expanded: !context.isCancelled())
        })
    }
    
    func addDismissalScalingAnimation() {
        presentingViewController.transitionCoordinator()?.animateAlongsideTransitionInView(presentingViewController.view, animation: { context in
            self.setScale(expanded: false)
            }, completion: { context in
                self.setScale(expanded: context.isCancelled())
        })
    }
    
    func fixPresentingViewControllerBounds() {
        guard let bounds = containerView?.bounds else { return }
        presentingViewController.view.bounds = bounds
    }
}

// MARK: - Notifications
private extension DraftPresentationController {
    
    func notifyThatDismissalWillBeginIfNonInteractive() {
        guard interactiveTransitioning == nil else { return }
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
            presentedViewController.navigationBar.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
        }
    }
    
    @objc private func panned(sender : UIPanGestureRecognizer) {
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        
        switch sender.state {
        case .Began:
            lastInteractionTimestamp = now
            interactiveTransitioning = UIPercentDrivenInteractiveTransition()
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            lastInteractionTimestamp = now
            interactiveTransitioning?.updateInteractiveTransition(min(sender.translationInView(containerView).y / (presentedViewController.view.bounds.height - dismissalInset), 1))
        case .Cancelled:
            interactiveTransitioning?.cancelInteractiveTransition()
            interactiveTransitioning = nil
        case .Ended:
            interactiveTransitioning?.completionCurve = .EaseOut
            if sender.velocityInView(containerView).y > 0 && (now - lastInteractionTimestamp) < 1 {
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
        guard interactiveTransitioning != nil && presentedViewController is DraftViewControllerProtocol else { return 0 }
        return OpenDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: OpenDraftsManager.sharedInstance.openDraftingViewControllers.count)
    }
}

// MARK: - Views

private extension DraftPresentationController {
    
    func configureViews() {
        wrappingView.frame = presentedViewController.view.frame
        wrappingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        wrappingView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = wrappingView.bounds
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
    
    func addPresentationOverlayAnimations() {
        addHeaderOverlayIfNeeded()
        
        headerOverlayView.alpha = 1
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ context in
            self.headerOverlayView.alpha = 0
        }, completion: { context in
            self.headerOverlayView.removeFromSuperview()
        })
    }
    
    func addDismissalOverlayAnimations() {
        
        if interactiveTransitioning != nil {
            addHeaderOverlayIfNeeded()
        }
        
        headerOverlayView.alpha = 0
        presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ context in
            self.headerOverlayView.alpha = 1
        }, completion: { context in
            self.headerOverlayView.removeFromSuperview()
        })
    }
}
