//
//  OpenDraftsManager.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

public class OpenDraftsManager {
    
    public static let sharedInstance = OpenDraftsManager()
    
    enum notifications : String {
        case didUpdateOpenDraftingControllers = "OpenDraftsManager.notifications.didUpdateOpenDraftingControllers"
    }
    
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didPresent(_:)), name: DraftPresentationController.notifications.didPresentDraftViewController.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(willDismissNonInteractive(_:)), name: DraftPresentationController.notifications.willDismissNonInteractiveDraftViewController.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private(set) var openDraftingViewControllers:[DraftViewControllerProtocol] = [] {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(notifications.didUpdateOpenDraftingControllers.rawValue, object: self, userInfo: nil)
        }
    }
    
    @objc private func didPresent(notification:NSNotification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController.rawValue] as? DraftViewControllerProtocol else { return }
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController }) + [viewController]
    }
    
    @objc private func willDismissNonInteractive(notification:NSNotification) {
        guard let viewController = notification.userInfo?[DraftPresentationController.notifications.keys.viewController.rawValue] as? DraftViewControllerProtocol else { return }
        
        openDraftingViewControllers = openDraftingViewControllers.filter({ $0 !== viewController })
    }
    
    public func presentDraft(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        if let viewController = self.openDraftingViewControllers.last as? UIViewController {
            presentingViewController.presentViewController(viewController, animated: animated, completion: completion)
            viewController.draftPresentationController?.hasBeenPresented = true
        }
    }
}
