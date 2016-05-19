//
//  DraftTransitioningDelegate.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

@objc(SEUIDraftTransitioningDelegate) public class DraftTransitioningDelegate : NSObject, UIViewControllerTransitioningDelegate {
    
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
    
    public func simulatedPresentingView(presentingViewController presentingViewController:UIViewController) -> UIView {
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
