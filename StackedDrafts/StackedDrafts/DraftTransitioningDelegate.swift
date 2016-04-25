//
//  DraftTransitioningDelegate.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

public class DraftTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    public static let sharedInstance = DraftTransitioningDelegate()
    
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        return DraftPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SingleDraftPresentationAnimatedTransitioning()
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DraftDismissalAnimatedTransitioning(interactiveTransitioning: dismissed.draftPresentationController?.interactiveTransitioning)
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return (animator as? DraftDismissalAnimatedTransitioning)?.interactiveTransitioning
    }
}
