//
//  OpenDraftsManager.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

/**
 This singleton class keeps track of all view controllers conforming to `DraftViewControllerProtocol` that are either presented or minimized.  When a change is observed in automatically updates the appearance of all instances of `OpenDraftsIndicatorViews`.
 
 - Note: This singleton is eligible for state restoration.  Because it can contain multiple detached view controllers, it is important that each draft view controller have a unique restoration identifier such as a UUID.
 */
@objc(SEUIOpenDraftsManager) public class OpenDraftsManager : NSObject {
    
    public static let sharedInstance:OpenDraftsManager = {
        let manager = OpenDraftsManager()
        UIApplication.registerObjectForStateRestoration(manager, restorationIdentifier: "OpenDraftsManager.sharedInstance")
        return manager
    }()
    
    enum notifications : String {
        case didUpdateOpenDraftingControllers = "OpenDraftsManager.notifications.didUpdateOpenDraftingControllers"
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didPresent(_:)), name: DraftPresentationController.notifications.didPresentDraftViewController.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(willDismissNonInteractive(_:)), name: DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// All instances of `DraftViewControllerProtocol` either presented or minimized.
    private(set) public var openDraftingViewControllers:[DraftViewControllerProtocol] = [] { didSet { notify() } }
    
    private func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(notifications.didUpdateOpenDraftingControllers.rawValue, object: self, userInfo: nil)
    }
    
    @objc private func didPresent(notification:NSNotification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController.rawValue] as? DraftViewControllerProtocol else { return }
        add(viewController)
    }
    
    @objc private func willDismissNonInteractive(notification:NSNotification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController.rawValue] as? DraftViewControllerProtocol else { return }
        remove(viewController)
    }
    
    /**
     Presents the open draft view controller or controllers from a source view controller.
     
     If a single draft view controller is open and minimized, it will be presented directly.  If multiple draft view controllers are minimized, a draft picker view controller will be presented, allowing the user to select any draft or dismiss and return to the presenting view controller.  If there are no view controllers to present, the fuction fails without error.
     
     - Parameters:
       - from: The presenting view controller.
       - animated: Whether to animate the transition.
       - completion: An optional callback notifying when the presentation has completed.
     */
    public func presentDraft(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        if self.openDraftingViewControllers.count > 1 {
            let viewController = OpenDraftSelectorViewController()
            viewController.setRestorationIdentifier("open-drafts", contingentOnViewController: presentingViewController)
            presentingViewController.presentViewController(viewController, animated: animated, completion: completion)
        } else if let viewController = self.openDraftingViewControllers.last as? UIViewController {
            presentingViewController.presentViewController(viewController, animated: animated, completion: completion)
            viewController.draftPresentationController?.hasBeenPresented = true
        }
    }
    
    public func add(viewController:DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController }) + [viewController]
    }
    
    public func remove(viewController:DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController })
    }
}

extension OpenDraftsManager : UIStateRestoring, UIObjectRestoration {
    public var objectRestorationClass: AnyObject.Type? { return OpenDraftsManager.self }
    
    public static func objectWithRestorationIdentifierPath(identifierComponents: [String], coder: NSCoder) -> UIStateRestoring? {
        return OpenDraftsManager.sharedInstance
    }
    
    public func encodeRestorableStateWithCoder(coder: NSCoder) {
        coder.encodeSafeArray(openDraftingViewControllers, forKey: "openDraftingViewControllers")
    }
    
    public func decodeRestorableStateWithCoder(coder: NSCoder) {
        openDraftingViewControllers = coder.decodeSafeArrayForKey("openDraftingViewControllers")
    }
    
    public func applicationFinishedRestoringState() {
        notify()
    }
}
