//
//  OpenDraftsIndicatorView.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

/**
 This control indicates the number of open drafts managed by `OpenDraftsManager.sharedInstance`, automatically updating its appearance.
 
 This view should be placed at the bottom of the screen as the draft presentation and dismissal animations are based on its appearance at that location.  By default, there are no actions wired to this control, but a touch up event should be used to present the view from its parent view controller.
 
 - Note: This view has a required height constraint that changes based on whether or not there are any open draft view controllers.  Other views should be positioned relative to its top.
 */
@IBDesignable
open class OpenDraftsIndicatorView: UIControl {
    
    @IBOutlet fileprivate var contentView: UIView!
    @IBOutlet fileprivate var mostRecentDraftTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var mostRecentDraftView: OpenDraftHeaderOverlayView!
    @IBOutlet fileprivate var secondDraftView: UIView!
    @IBOutlet fileprivate var thirdDraftView: UIView!
    
    fileprivate static let displayedHeight:CGFloat = 44
    fileprivate var heightConstraint:NSLayoutConstraint!
    fileprivate var intrinsicHeight:CGFloat = 0 { didSet { heightConstraint.constant = intrinsicHeight } }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }
    
    convenience public init() {
        self.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        loadContentView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func loadContentView() {
        UINib(nibName: "OpenDraftsIndicatorView.contentView", bundle: Bundle(for: OpenDraftsIndicatorView.self)).instantiate(withOwner: self, options: nil)
        
        heightConstraint = attr(self, .height) == intrinsicHeight
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            attr(contentView, .leading) == attr(self, .leading),
            attr(contentView, .trailing) == attr(self, .trailing),
            attr(contentView, .top) == attr(self, .top),
            attr(contentView, .height) == OpenDraftsIndicatorView.displayedHeight,
            heightConstraint
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateOpenDraftingControllers(_:)), name: OpenDraftsManager.notifications.didUpdateOpenDraftingControllers, object: OpenDraftsManager.sharedInstance)
    }
    
    override open var accessibilityLabel: String? {
        set(value) { super.accessibilityLabel = value }
        get { return super.accessibilityLabel ?? customAccessibilityLabel }
    }
    
    override open var accessibilityHint: String? {
        set(value) { super.accessibilityHint = value }
        get { return super.accessibilityHint ?? customAccessibilityHint }
    }
    
    fileprivate var customAccessibilityLabel:String? = nil
    fileprivate var customAccessibilityHint:String? = nil
    
    @objc fileprivate func didUpdateOpenDraftingControllers(_: Notification?) {
        let openDrafts = OpenDraftsManager.sharedInstance.openDraftingViewControllers
        setMostRecentDraftTitle(openDrafts.last?.draftTitle, numberOfOpenDrafts: openDrafts.count)
    }
    
    fileprivate func setMostRecentDraftTitle(_ mostRecentDraftTitle:String?, numberOfOpenDrafts:Int) {
        mostRecentDraftView.labelText = mostRecentDraftTitle
        secondDraftView.isHidden = numberOfOpenDrafts < 2
        thirdDraftView.isHidden = numberOfOpenDrafts < 3
        mostRecentDraftTopConstraint.constant = CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
        intrinsicHeight = numberOfOpenDrafts > 0 ? OpenDraftsIndicatorView.displayedHeight : 0
        
        switch numberOfOpenDrafts {
        case 0:
            customAccessibilityLabel = nil
            customAccessibilityHint = nil
        case 1:
            customAccessibilityLabel = NSLocalizedString("One minimized draft: {title}", comment: "Accessibility")
                .replacingOccurrences(of: "{title}", with: mostRecentDraftTitle ?? "Unknown")
            customAccessibilityHint = NSLocalizedString("Double tap to open", comment: "Accessibility")
        default:
            customAccessibilityLabel = NSLocalizedString("{count} minimized drafts. Most recent: {title}", comment: "Accessibility")
                .replacingOccurrences(of: "{count}", with: NumberFormatter().string(from: NSNumber(value: numberOfOpenDrafts)) ?? String(numberOfOpenDrafts))
                .replacingOccurrences(of: "{title}", with: mostRecentDraftTitle ?? "Unknown")
            customAccessibilityHint = NSLocalizedString("Double tap to select", comment: "Accessibility")
        }
        
        isAccessibilityElement = true
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setMostRecentDraftTitle("Able was I, ere I saw Elba", numberOfOpenDrafts: 2)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.point(inside: point, with: event) ? self : nil
    }
    
    class func visibleHeaderHeight(numberOfOpenDrafts: Int) -> CGFloat {
        if numberOfOpenDrafts == 0 {
            return 0
        } else {
            return 44 - CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
        }
    }
}
