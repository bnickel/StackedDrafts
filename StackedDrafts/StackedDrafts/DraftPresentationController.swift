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
    
    // Location
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        let frame = super.frameOfPresentedViewInContainerView()
        let insets = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
        return UIEdgeInsetsInsetRect(frame, insets)
    }
    
    // Parent scaling
    
    private func setScale(expanded expanded: Bool) {
        
        if expanded {
            let fromMeasurement = presentingViewController.view.bounds.width
            let fromScale = (fromMeasurement - 30) / fromMeasurement
            presentingViewController.view.transform = CGAffineTransformMakeScale(fromScale, fromScale)
        } else {
            presentingViewController.view.transform = CGAffineTransformIdentity
        }
    }
    
    override func presentationTransitionWillBegin() {
        presentingViewController.transitionCoordinator()?.animateAlongsideTransitionInView(containerView!, animation: { context in
            self.setScale(expanded: true)
        }, completion: { context in
            self.setScale(expanded: !context.isCancelled())
        })
    }
    
    override func dismissalTransitionWillBegin() {
        
        if interactiveTransitioning == nil {
            NSNotificationCenter.defaultCenter().postNotificationName(notifications.willDismissNonInteractiveDraftViewController.rawValue, object: self, userInfo: [notifications.keys.viewController.rawValue: presentedViewController])
        }
        
        presentingViewController.transitionCoordinator()?.animateAlongsideTransitionInView(presentingViewController.view, animation: { context in
            self.setScale(expanded: false)
        }, completion: { context in
            self.setScale(expanded: context.isCancelled())
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let bounds = containerView?.bounds else { return }
        presentingViewController.view.bounds = bounds
    }
    
    // Interactive dismissal
    
    override func presentationTransitionDidEnd(completed: Bool) {
        guard completed else { return }
        if let presentedViewController = presentedViewController as? DraftViewControllerProtocol {
            presentedViewController.draggableView?.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
        } else if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.navigationBar.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(notifications.didPresentDraftViewController.rawValue, object: self, userInfo: [notifications.keys.viewController.rawValue: presentedViewController])
    }
    
    var interactiveTransitioning:UIPercentDrivenInteractiveTransition? = nil
    private var lastInteractionTimestamp:NSTimeInterval = 0
    
    @objc private func panned(sender : UIPanGestureRecognizer) {
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        
        switch sender.state {
        case .Began:
            lastInteractionTimestamp = now
            interactiveTransitioning = UIPercentDrivenInteractiveTransition()
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            lastInteractionTimestamp = now
            interactiveTransitioning?.updateInteractiveTransition(sender.translationInView(containerView).y / presentedViewController.view.bounds.height)
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
}
