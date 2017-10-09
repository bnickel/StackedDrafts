//
//  ViewController.swift
//  Demo
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit
import StackedDrafts

class PresentingViewController: UIViewController, OpenDraftsIndicatorSource {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        DraftTransitioningDelegate.shared = DraftTransitioningDelegate(openDraftsIndicatorSource: self)
    }
    
    @IBOutlet weak var openDraftsIndicatorView: OpenDraftsIndicatorView!
    
    @IBAction func done(segue: UIStoryboardSegue) { }
    
    @IBAction func minimize(segue: UIStoryboardSegue) {
        segue.source.draftPresentationController?.shouldMinimize = true
    }
    
    @IBAction func draftRequested() {
        OpenDraftsManager.shared.presentDraft(from: self, openDraftsIndicatorSource: self, animated: true)
    }
    
    func visibleHeaderHeight(numberOfOpenDrafts: Int) -> CGFloat {
        return openDraftsIndicatorView.visibleHeaderHeight(numberOfOpenDrafts: numberOfOpenDrafts)
    }
}

extension DraftTransitioningDelegate {
    static var shared: DraftTransitioningDelegate!
}
