//
//  OpenDraftsManager.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let openDraftsManagerDidUpdateOpenDraftingControllers = NSNotification.Name(rawValue: "OpenDraftsManager.notifications.didUpdateOpenDraftingControllers")
    
}

/**
 This singleton class keeps track of all view controllers conforming to `DraftViewControllerProtocol` that are either presented or minimized.  When a change is observed in automatically updates the appearance of all instances of `OpenDraftsIndicatorViews`.
 
 - Note: This singleton is eligible for state restoration.  Because it can contain multiple detached view controllers, it is important that each draft view controller have a unique restoration identifier such as a UUID.
 */
@objc(SEUIOpenDraftsManager) open class OpenDraftsManager : NSObject {
    
    @objc(sharedInstance) open static let shared: OpenDraftsManager = {
        let manager = OpenDraftsManager()
        UIApplication.registerObject(forStateRestoration: manager, restorationIdentifier: "OpenDraftsManager.sharedInstance")
        return manager
    }()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didPresent(_:)), name: .draftPresentationControllerDidPresentDraftViewController, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willDismissNonInteractive(_:)), name: .draftPresentationControllerWillDismissNonInteractiveDraftViewController, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// All instances of `DraftViewControllerProtocol` either presented or minimized.
    private(set) open var openDraftingViewControllers: [UIViewController & DraftViewControllerProtocol] = [] { didSet { notify() } }
    
    private func notify() {
        NotificationCenter.default.post(name: .openDraftsManagerDidUpdateOpenDraftingControllers, object: self, userInfo: nil)
    }
    
    @objc private func didPresent(_ notification: Notification) {
        guard let viewController = notification.presentedDraftViewController else { return }
        add(viewController)
    }
    
    @objc private func willDismissNonInteractive(_ notification: Notification) {
        guard let viewController = notification.presentedDraftViewController else { return }
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
        } else if let viewController = openDraftingViewControllers.last {
            presentingViewController.present(viewController, animated: animated, completion: completion)
            viewController.draftPresentationController?.hasBeenPresented = true
        }
    }
    
    open func add(_ viewController: UIViewController & DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController }) + [viewController]
    }
    
    open func remove(_ viewController: UIViewController & DraftViewControllerProtocol) {
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController })
    }
}

extension OpenDraftsManager : UIStateRestoring, UIObjectRestoration {
    
    public var objectRestorationClass: UIObjectRestoration.Type? {
        return OpenDraftsManager.self
    }
    
    public static func object(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIStateRestoring? {
        return shared
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
