//
//  DraftDismissalAnimatedTransitioning.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class DraftDismissalAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    let interactiveTransitioning:UIViewControllerInteractiveTransitioning?
    
    init(interactiveTransitioning:UIViewControllerInteractiveTransitioning?) {
        self.interactiveTransitioning = interactiveTransitioning
        super.init()
    }
    
    /**
     Sooo... in iOS 8 if the gap between `updateInteractiveTransition` and `finishInteractiveTransition` is below transitionDuration (with some amount of wiggle room), the animation's completion block will never call.  This hack drops the duration really low on iOS 8, then cranks down the interaction completion speed to compensate.
     */
    static var hackDuration:NSTimeInterval {
        if #available(iOS 9, *) {
            return normalDuration
        } else {
            return 0.05
        }
    }
    
    static let normalDuration:NSTimeInterval = 0.3
    
    static var interactiveCompletionSpeed: CGFloat {
        return CGFloat(hackDuration / normalDuration)
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return interactiveTransitioning != nil ? self.dynamicType.hackDuration : self.dynamicType.normalDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(transitionContext)
        let animationOptions:UIViewAnimationOptions = interactiveTransitioning != nil ? .CurveLinear : .CurveEaseInOut
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        let initialFrameRelativeToSuperview = transitionContext.initialFrameForViewController(fromViewController)
        let initialFrame = fromViewController.view.superview!.convertRect(initialFrameRelativeToSuperview, toView: fromView.superview)
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        let finalInset = fromViewController.draftPresentationController?.dismissalInset ?? 0
        
        var finalFrame = initialFrame
        finalFrame.origin.y = initialFrame.maxY - finalInset
        
        
        fromView.frame = initialFrame
        toView.frame = transitionContext.finalFrameForViewController(toViewController)
        toView.layoutIfNeeded()
        transitionContext.containerView()?.insertSubview(toView, atIndex: 0)
        
        let initialTransform = fromView.transform
        let animationTransform = DraftPresentationController.presenterTransform(height: toView.bounds.height)
        toView.transform = animationTransform
        
        UIView.animateWithDuration(duration, delay: 0, options: animationOptions, animations: {
            fromView.endEditing(true)
            fromView.frame = finalFrame
            toView.transform = initialTransform
        }, completion: { _ in
            toView.transform = initialTransform
            if transitionContext.transitionWasCancelled() {
                toView.removeFromSuperview()
                transitionContext.completeTransition(false)
            } else {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
    }
}
