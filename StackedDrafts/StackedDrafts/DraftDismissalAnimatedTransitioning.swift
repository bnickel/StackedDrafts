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
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(transitionContext)
        let animationOptions:UIViewAnimationOptions = interactiveTransitioning != nil ? .CurveLinear : .CurveEaseInOut
        
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        
        let initialFrame = transitionContext.initialFrameForViewController(fromViewController)
        var finalFrame = initialFrame
        
        finalFrame.origin.y = initialFrame.maxY
        
        fromViewController.view.frame = initialFrame
        transitionContext.containerView()?.addSubview(fromViewController.view)
        
        UIView.animateWithDuration(duration, delay: 0, options: animationOptions, animations: {
            fromViewController.view.frame = finalFrame
        }, completion: { _ in
            
            if transitionContext.transitionWasCancelled() {
                transitionContext.completeTransition(false)
            } else {
                fromViewController.view.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        })
    }

}
