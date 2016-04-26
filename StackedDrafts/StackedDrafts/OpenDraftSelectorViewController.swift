//
//  OpenDraftSelectorViewController.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class OpenDraftSelectorViewController: UIViewController {
    
    private let normalLayout = AllDraftsCollectionViewLayout()
    private let initialLayout = PresenterSelectedLayout()
    private let draftSelectedLayout = DraftSelectedCollectionViewLayout()
    private var selectableViewControllers:[DraftViewControllerProtocol] = []
    
    private var collectionView:UICollectionView!
    
    unowned let source: UIViewController
    
    init(source: UIViewController) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .OverFullScreen
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let frame = CGRectMake(0, 0, 100, 100)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: initialLayout)
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        let view = UIView(frame: frame)
        view.addSubview(collectionView)
        
        self.collectionView = collectionView
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OpenDraftCollectionViewCell.register(with: collectionView)
        selectableViewControllers = OpenDraftsManager.sharedInstance.openDraftingViewControllers
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
    
    func render(draftViewController:DraftViewControllerProtocol) -> UIView {
        guard let viewController = draftViewController as? UIViewController else { preconditionFailure() }
        addChildViewController(viewController)
        viewController.view.frame = view.bounds
        view.insertSubview(viewController.view, belowSubview: collectionView)
        
        defer {
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
        
        return viewController.view.snapshotViewAfterScreenUpdates(true)
    }
    
    var snapshots:[UIView]? = nil
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSnapshotsIfNeeded()
        dispatch_async(dispatch_get_main_queue()) { 
            self.collectionView.setCollectionViewLayout(self.normalLayout, animated: true)
        }
    }
    
    func loadSnapshotsIfNeeded() {
        guard snapshots == nil else { return }
        snapshots = [source.view.snapshotViewAfterScreenUpdates(false)] + selectableViewControllers.map(render)
        
        for indexPath in collectionView.indexPathsForVisibleItems() {
            (collectionView.cellForItemAtIndexPath(indexPath) as? OpenDraftCollectionViewCell)?.snapshotView = snapshots?[indexPath.item]
        }
    }
}

extension OpenDraftSelectorViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + selectableViewControllers.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let view = OpenDraftCollectionViewCell.cell(at: indexPath, collectionView: collectionView)
        view.snapshotView = snapshots?[indexPath.item]
        
        if indexPath.item == 0 {
            view.showHeader = false
        } else {
            view.showHeader = true
            view.draftTitle = selectableViewControllers[indexPath.item - 1].draftTitle
        }
        
        return view
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if collectionView.collectionViewLayout != normalLayout {
            collectionView.setCollectionViewLayout(normalLayout, animated: true)
        } else if indexPath.item == 0 {
            collectionView.setCollectionViewLayout(initialLayout, animated: true)
        } else {
            draftSelectedLayout.selectedIndex = indexPath.item
            collectionView.setCollectionViewLayout(draftSelectedLayout, animated: true)
        }
    }
}

extension OpenDraftSelectorViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.view.bounds.size
    }
}
