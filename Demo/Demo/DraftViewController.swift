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
    
    let draftTitle: String? = "New Message \(DraftViewController.getIndex())"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        transitioningDelegate = DraftTransitioningDelegate.sharedInstance
        modalPresentationStyle = .Custom
    }
}
