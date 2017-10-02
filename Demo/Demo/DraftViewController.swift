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
    
    static let sharedDelegate = DraftTransitioningDelegate()
    
    @IBOutlet var draggableView: UIView?
    @IBOutlet var textField: UITextField!
    
    static var count = 0
    static func getIndex() -> Int { count += 1; return count }
    
    private(set) lazy var draftTitle: String? = "New Message \(DraftViewController.getIndex())"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        restorationIdentifier = UUID().uuidString
        restorationClass = DraftViewController.self
        transitioningDelegate = DraftViewController.sharedDelegate
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let orangeView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 10))
        orangeView.backgroundColor = .orange
        textField.inputAccessoryView = orangeView
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension DraftViewController: UIViewControllerRestoration {
    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let storyboard = coder.decodeObject(forKey: UIStateRestorationViewControllerStoryboardKey) as? UIStoryboard else { return nil }
        let viewController = storyboard.instantiateViewController(withIdentifier: "presented")
        viewController.restorationIdentifier = identifierComponents.last as? String
        return viewController
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(draftTitle, forKey: "title")
        coder.encode(DraftViewController.count, forKey: "count")
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        draftTitle = coder.decodeObject(forKey: "title") as? String
        DraftViewController.count = coder.decodeInteger(forKey: "count")
    }
}
