//
//  SingleDraftPresentationAnimatedTransitioning.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class SingleDraftPresentationAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(transitionContext)
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        let finalFrameRelativeToSuperview = transitionContext.finalFrameForViewController(toViewController)
        let finalFrame = toViewController.view.superview!.convertRect(finalFrameRelativeToSuperview, toView: toView.superview)
        
        let initialInset = toViewController.draftPresentationController?.presentationInset ?? 0
        
        var initialFrame = finalFrame
        initialFrame.origin.y = finalFrame.maxY - initialInset
        
        transitionContext.containerView()?.addSubview(toView)
        toView.frame = initialFrame
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseOut, animations: {
            toView.frame = finalFrame
        }, completion: { _ in
            if transitionContext.transitionWasCancelled() {
                toView.removeFromSuperview()
                transitionContext.completeTransition(false)
            } else {
                transitionContext.completeTransition(true)
            }
        })
    }

}