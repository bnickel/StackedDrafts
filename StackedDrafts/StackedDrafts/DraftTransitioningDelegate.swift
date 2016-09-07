//
//  DraftTransitioningDelegate.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit


/**
 This class manages animation, presentation, and interactive dismissal of view controllers conforming to `DraftViewControllerProtocol`.  Before being presented, draft view controllers should set their `transitioningDelegate` to an instance of this class and `modalPresentationStyle` to `.Custom`.
 
 - Note: When the presentation animation is completed, the presenting view controller is replaced with a view that simulates its color and navigation bar appearance. Subclasses may override `simulatedPresentingView(for:)` to handle complex view controller styles.
 */
@objc(SEUIDraftTransitioningDelegate) public class DraftTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController?, sourceViewController source: UIViewController) -> UIPresentationController? {
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
    
    /**
     This method is called by the presentation controller when the animation completes in order to show what appears to be the top of the presenting view controller behind the presented view controller.  The view controller is obscured in such a way that no more than the top 20pt should be visible in when the status bar is visible and 5pt when the status bar is hidden.  This should cause most or all navigation bar content hidden so a solid background would be sufficient.
     
     The default implementation of this method renders either a solid background for a presenting UIViewController or a matching navigation bar for a presenting UINavigationController.  This method can be overwritten in a subclass to handle more complex requirements.
     
     - Parameter presentingViewController: The view controller that should be simulated.
     
     - Returns: The UIView to display.
     
     */
    public func simulatedPresentingView(for presentingViewController:UIViewController) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.backgroundColor = presentingViewController.view.backgroundColor
        if let navigationController = presentingViewController as? UINavigationController where !navigationController.navigationBarHidden {
            let sourceNavigationBar = navigationController.navigationBar
            let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 100, height: 64))
            navigationBar.backgroundColor = sourceNavigationBar.backgroundColor
            navigationBar.barTintColor = sourceNavigationBar.barTintColor
            navigationBar.translucent = sourceNavigationBar.translucent
            navigationBar.autoresizingMask = [.FlexibleBottomMargin, .FlexibleWidth]
            view.backgroundColor = navigationController.visibleViewController?.view.backgroundColor ?? navigationController.view.backgroundColor
            view.addSubview(navigationBar)
        }
        return view
    }
}
