//
//  OpenDraftCollectionViewCell.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

class OpenDraftCollectionViewCell: UICollectionViewCell {

    @IBOutlet private var previewContainerView: UIView!
    @IBOutlet private var headerView: OpenDraftHeaderOverlayView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerView.labelText = "Able was I, ere I saw Elba."
    }

    @IBAction private func closeButtonTapped() {
    }
    
    private static let reuseIdentifier = "OpenDraftCollectionViewCell"
    
    class func register(with collectionView: UICollectionView) {
        collectionView.registerNib(UINib(nibName: "OpenDraftCollectionViewCell", bundle: NSBundle(forClass: self)), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    class func cell(at indexPath:NSIndexPath, collectionView: UICollectionView) -> OpenDraftCollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(OpenDraftCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! OpenDraftCollectionViewCell
    }
}
