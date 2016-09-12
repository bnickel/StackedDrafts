//
//  SingleDraftPresentationAnimatedTransitioning.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class SingleDraftPresentationAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let duration = transitionDuration(using: transitionContext)
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) ?? fromViewController.view!
        
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        let ownsFromView = toViewController.presentationController?.shouldRemovePresentersView ?? false
        
        let finalFrameRelativeToSuperview = transitionContext.finalFrame(for: toViewController)
        let finalFrame = toViewController.view.superview!.convert(finalFrameRelativeToSuperview, to: toView.superview)
        
        let initialInset = toViewController.draftPresentationController?.presentationInset ?? 0
        
        var initialFrame = finalFrame
        initialFrame.origin.y = finalFrame.maxY - initialInset
        
        let initialTransform = fromView.transform
        let animationTransform = DraftPresentationController.presenterTransform(height: fromView.bounds.height)
        
        transitionContext.containerView.addSubview(toView)
        toView.frame = initialFrame
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
            fromView.transform = animationTransform
            toView.frame = finalFrame
        }, completion: { _ in
            fromView.transform = initialTransform
            if transitionContext.transitionWasCancelled {
                toView.removeFromSuperview()
                transitionContext.completeTransition(false)
            } else {
                if ownsFromView {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(true)
            }
        })
    }
}
