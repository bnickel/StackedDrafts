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
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var headerView: OpenDraftHeaderOverlayView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerView.labelText = "Able was I, ere I saw Elba."
    }
    
    var closeTapped:((OpenDraftCollectionViewCell) -> Void)?

    @IBAction private func closeButtonTapped() {
        closeTapped?(self)
    }
    
    private static let reuseIdentifier = "OpenDraftCollectionViewCell"
    
    class func register(with collectionView: UICollectionView) {
        collectionView.registerNib(UINib(nibName: "OpenDraftCollectionViewCell", bundle: NSBundle(forClass: self)), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    class func cell(at indexPath:NSIndexPath, collectionView: UICollectionView) -> OpenDraftCollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(OpenDraftCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! OpenDraftCollectionViewCell
    }
    
    var snapshotView:UIView? {
        didSet {
            previewContainerView.subviews.last?.removeFromSuperview()
            if let snapshotView = snapshotView {
                snapshotView.translatesAutoresizingMaskIntoConstraints = true
                snapshotView.autoresizingMask = [.FlexibleRightMargin, .FlexibleBottomMargin]
                snapshotView.frame.origin = CGPointZero
                previewContainerView.addSubview(snapshotView)
            }
        }
    }
    
    var showHeader:Bool = true {
        didSet {
            headerView.alpha = showHeader ? 1 : 0
            closeButton.alpha = showHeader && showCloseButton ? 1 : 0
            updateAccessibilityElements()
        }
    }
    
    var showCloseButton:Bool = true {
        didSet {
            closeButton.alpha = showHeader && showCloseButton ? 1 : 0
            updateAccessibilityElements()
        }
    }
    
    var draftTitle:String? {
        didSet {
            headerView.labelText = draftTitle
            updateAccessibilityElements()
        }
    }
    
    // This is just lazy right here but want to ship.
    // TODO: Don't be lazy.
    func updateAccessibilityElements() {
        previewContainerView.isAccessibilityElement = true
        previewContainerView.accessibilityTraits = UIAccessibilityTraitButton
        previewContainerView.accessibilityLabel = showHeader ? NSLocalizedString("Draft: ", comment: "Accessibility") + (headerView.labelText ?? "Untitled") : NSLocalizedString("Dismiss drafts", comment: "Accessibility")
        closeButton.accessibilityLabel = NSLocalizedString("Close ", comment: "Accessibility") + (headerView.labelText ?? "Untitled")
        accessibilityElements = showCloseButton && showHeader ? [previewContainerView, closeButton] : [previewContainerView]
    }
}
