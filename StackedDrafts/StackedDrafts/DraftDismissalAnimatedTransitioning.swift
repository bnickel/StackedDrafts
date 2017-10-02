//
//  DraftDismissalAnimatedTransitioning.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

final class DraftDismissalAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let interactiveTransitioning: UIViewControllerInteractiveTransitioning?
    
    init(interactiveTransitioning: UIViewControllerInteractiveTransitioning?) {
        self.interactiveTransitioning = interactiveTransitioning
        super.init()
    }
    
    /**
     Sooo... in iOS 8 if the gap between `updateInteractiveTransition` and `finishInteractiveTransition` is below transitionDuration (with some amount of wiggle room), the animation's completion block will never call.  This hack drops the duration really low on iOS 8, then cranks down the interaction completion speed to compensate.
     */
    static var hackDuration: TimeInterval {
        if #available(iOS 9, *) {
            return normalDuration
        } else {
            return 0.05
        }
    }
    
    static let normalDuration: TimeInterval = 0.3
    
    static var interactiveCompletionSpeed: CGFloat {
        return CGFloat(hackDuration / normalDuration)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return interactiveTransitioning != nil ? DraftDismissalAnimatedTransitioning.hackDuration : DraftDismissalAnimatedTransitioning.normalDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(using: transitionContext)
        let animationOptions: UIViewAnimationOptions = interactiveTransitioning != nil ? .curveLinear : []
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        
        let initialFrameRelativeToSuperview = transitionContext.initialFrame(for: fromViewController)
        let initialFrame = fromViewController.view.superview!.convert(initialFrameRelativeToSuperview, to: fromView.superview)
        
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) ?? toViewController.view!
        let ownsToView = fromViewController.presentationController?.shouldRemovePresentersView ?? false
        
        let finalInset = fromViewController.draftPresentationController?.dismissalInset ?? 0
        
        var finalFrame = initialFrame
        finalFrame.origin.y = initialFrame.maxY - finalInset
        
        fromView.frame = initialFrame
        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.layoutIfNeeded()
        if ownsToView {
            transitionContext.containerView.insertSubview(toView, at: 0)
        }
        
        let initialTransform = fromView.transform
        let animationTransform = DraftPresentationController.presenterTransform(height: toView.bounds.height)
        toView.transform = animationTransform
        
        UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: {
            fromView.endEditing(true)
            fromView.frame = finalFrame
            toView.transform = initialTransform
        }, completion: { _ in
            toView.transform = initialTransform
            if transitionContext.transitionWasCancelled {
                if ownsToView {
                    toView.removeFromSuperview()
                }
                transitionContext.completeTransition(false)
            } else {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
    }
}
