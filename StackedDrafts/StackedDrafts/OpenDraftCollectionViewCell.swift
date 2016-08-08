//
//  OpenDraftCollectionViewCell.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    func configure() {
        (layer as! CAGradientLayer).colors = [UIColor.blackColor().colorWithAlphaComponent(0), UIColor.blackColor().colorWithAlphaComponent(0.5)].map({ $0.CGColor })
    }
}

class OpenDraftCollectionViewCell: UICollectionViewCell {

    @IBOutlet private var previewContainerView: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var headerView: OpenDraftHeaderOverlayView!
    @IBOutlet var gradientView: GradientView!
    
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
    
    var showGradientView:Bool = true {
        didSet {
            gradientView.alpha = showGradientView ? 1 : 0
        }
    }
    
    var draftTitle:String? {
        didSet {
            headerView.labelText = draftTitle
            updateAccessibilityElements()
        }
    }
    
    func updateAccessibilityElements() {
        previewContainerView.isAccessibilityElement = true
        previewContainerView.accessibilityTraits = UIAccessibilityTraitButton
        previewContainerView.accessibilityLabel = showHeader ? NSLocalizedString("Draft: ", comment: "Accessibility") + (headerView.labelText ?? "Untitled") : NSLocalizedString("Dismiss drafts", comment: "Accessibility")
        closeButton.accessibilityLabel = NSLocalizedString("Close ", comment: "Accessibility") + (headerView.labelText ?? "Untitled")
        accessibilityElements = showCloseButton && showHeader ? [previewContainerView, closeButton] : [previewContainerView]
    }
}
