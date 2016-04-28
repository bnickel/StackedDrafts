//
//  DraftViewController.swift
//  Demo
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit
import StackedDrafts

class DraftViewController: UIViewController, DraftViewControllerProtocol {
    
    @IBOutlet var draggableView: UIView?
    
    static var count = 0
    static func getIndex() -> Int { count += 1; return count }
    
    private(set) lazy var draftTitle: String? = "New Message \(DraftViewController.getIndex())"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        restorationIdentifier = NSUUID().UUIDString
        restorationClass = DraftViewController.self
        transitioningDelegate = DraftTransitioningDelegate.sharedInstance
        modalPresentationStyle = .Custom
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension DraftViewController: UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        guard let storyboard = coder.decodeObjectForKey(UIStateRestorationViewControllerStoryboardKey) as? UIStoryboard else { return nil }
        let viewController = storyboard.instantiateViewControllerWithIdentifier("presented")
        viewController.restorationIdentifier = identifierComponents.last as? String
        return viewController
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeObject(draftTitle, forKey: "title")
        coder.encodeInteger(DraftViewController.count, forKey: "count")
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        draftTitle = coder.decodeObjectForKey("title") as? String
        DraftViewController.count = coder.decodeIntegerForKey("count")
    }
}
