//
//  ViewController.swift
//  Demo
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit
import StackedDrafts

class PresentingViewController: UIViewController {
    
    @IBAction func done(segue: UIStoryboardSegue) { }
    
    @IBAction func minimize(segue: UIStoryboardSegue) {
        segue.source.draftPresentationController?.shouldMinimize = true
    }
    
    @IBAction func draftRequested() {
        OpenDraftsManager.shared.presentDraft(from: self, animated: true)
    }
}

