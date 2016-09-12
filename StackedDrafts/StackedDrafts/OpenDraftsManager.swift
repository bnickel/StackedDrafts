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
@objc(SEUIOpenDraftsManager) open class OpenDraftsManager : NSObject {
    
    open static let sharedInstance:OpenDraftsManager = {
        let manager = OpenDraftsManager()
        UIApplication.registerObject(forStateRestoration: manager, restorationIdentifier: "OpenDraftsManager.sharedInstance")
        return manager
    }()
    
    struct notifications {
        static let didUpdateOpenDraftingControllers = NSNotification.Name(rawValue: "OpenDraftsManager.notifications.didUpdateOpenDraftingControllers")
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didPresent(_:)), name: DraftPresentationController.notifications.didPresentDraftViewController, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willDismissNonInteractive(_:)), name: DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// All instances of `DraftViewControllerProtocol` either presented or minimized.
    fileprivate(set) open var openDraftingViewControllers:[DraftViewControllerProtocol] = [] { didSet { notify() } }
    
    fileprivate func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notifications.didUpdateOpenDraftingControllers.rawValue), object: self, userInfo: nil)
    }
    
    @objc fileprivate func didPresent(_ notification:Notification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController] as? DraftViewControllerProtocol else { return }
        add(viewController)
    }
    
    @objc fileprivate func willDismissNonInteractive(_ notification:Notification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController] as? DraftViewControllerProtocol else { return }
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
    open func presentDraft(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        if self.openDraftingViewControllers.count > 1 {
            let viewController = OpenDraftSelectorViewController()
            viewController.setRestorationIdentifier("open-drafts", contingentOnViewController: presentingViewController)
            presentingViewController.present(viewController, animated: animated, completion: completion)
        } else if let viewController = self.openDraftingViewControllers.last as? UIViewController {
            presentingViewController.present(viewController, animated: animated, completion: completion)
            viewController.draftPresentationController?.hasBeenPresented = true
        }
    }
    
    open func add(_ viewController:DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController }) + [viewController]
    }
    
    open func remove(_ viewController:DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController })
    }
}

extension OpenDraftsManager : UIStateRestoring, UIObjectRestoration {
    
    public var objectRestorationClass: UIObjectRestoration.Type? {
        return OpenDraftsManager.self
    }
    
    public static func object(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIStateRestoring? {
        return OpenDraftsManager.sharedInstance
    }
    
    public func encodeRestorableState(with coder: NSCoder) {
        coder.encodeSafeArray(openDraftingViewControllers, forKey: "openDraftingViewControllers")
    }
    
    public func decodeRestorableState(with coder: NSCoder) {
        openDraftingViewControllers = coder.decodeSafeArrayForKey("openDraftingViewControllers")
    }
    
    public func applicationFinishedRestoringState() {
        notify()
    }
}
