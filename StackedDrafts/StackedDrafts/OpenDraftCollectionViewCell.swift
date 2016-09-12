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
    
    override class var layerClass : AnyClass {
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
        (layer as! CAGradientLayer).colors = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.5)].map({ $0.cgColor })
    }
}

class OpenDraftCollectionViewCell: UICollectionViewCell {

    @IBOutlet fileprivate var previewContainerView: UIView!
    @IBOutlet fileprivate var closeButton: UIButton!
    @IBOutlet fileprivate var headerView: OpenDraftHeaderOverlayView!
    @IBOutlet var gradientView: GradientView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerView.labelText = "Able was I, ere I saw Elba."
    }
    
    var closeTapped:((OpenDraftCollectionViewCell) -> Void)?

    @IBAction fileprivate func closeButtonTapped() {
        closeTapped?(self)
    }
    
    fileprivate static let reuseIdentifier = "OpenDraftCollectionViewCell"
    
    class func register(with collectionView: UICollectionView) {
        collectionView.register(UINib(nibName: "OpenDraftCollectionViewCell", bundle: Bundle(for: self)), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    class func cell(at indexPath:IndexPath, collectionView: UICollectionView) -> OpenDraftCollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: OpenDraftCollectionViewCell.reuseIdentifier, for: indexPath) as! OpenDraftCollectionViewCell
    }
    
    var snapshotView:UIView? {
        didSet {
            previewContainerView.subviews.last?.removeFromSuperview()
            if let snapshotView = snapshotView {
                snapshotView.translatesAutoresizingMaskIntoConstraints = true
                snapshotView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
                snapshotView.frame.origin = CGPoint.zero
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
