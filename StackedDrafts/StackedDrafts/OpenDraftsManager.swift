//
//  OpenDraftsManager.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

public class OpenDraftsManager : NSObject {
    
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
    
    private(set) var openDraftingViewControllers:[DraftViewControllerProtocol] = [] { didSet { notify() } }
    
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
    
    func remove(viewController:DraftViewControllerProtocol) {
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
