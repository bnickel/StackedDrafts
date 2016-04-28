//
//  OpenDraftsIndicatorView.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/21/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

@IBDesignable
public class OpenDraftsIndicatorView: UIControl {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var mostRecentDraftTopConstraint: NSLayoutConstraint!
    @IBOutlet private var mostRecentDraftView: OpenDraftHeaderOverlayView!
    @IBOutlet private var secondDraftView: UIView!
    @IBOutlet private var thirdDraftView: UIView!
    
    private static let displayedHeight:CGFloat = 44
    private var heightConstraint:NSLayoutConstraint!
    private var intrinsicHeight:CGFloat = 0 { didSet { heightConstraint.constant = intrinsicHeight } }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }
    
    convenience public init() {
        self.init(frame: CGRectZero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        loadContentView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func loadContentView() {
        UINib(nibName: "OpenDraftsIndicatorView.contentView", bundle: NSBundle(forClass: OpenDraftsIndicatorView.self)).instantiateWithOwner(self, options: nil)
        
        heightConstraint = attr(self, .Height) == intrinsicHeight
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activateConstraints([
            attr(contentView, .Leading) == attr(self, .Leading),
            attr(contentView, .Trailing) == attr(self, .Trailing),
            attr(contentView, .Top) == attr(self, .Top),
            attr(contentView, .Height) == OpenDraftsIndicatorView.displayedHeight,
            heightConstraint
        ])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didUpdateOpenDraftingControllers(_:)), name: OpenDraftsManager.notifications.didUpdateOpenDraftingControllers.rawValue, object: OpenDraftsManager.sharedInstance)
    }
    
    override public var accessibilityLabel: String? {
        set(value) { super.accessibilityLabel = value }
        get { return super.accessibilityLabel ?? customAccessibilityLabel }
    }
    
    override public var accessibilityHint: String? {
        set(value) { super.accessibilityHint = value }
        get { return super.accessibilityHint ?? customAccessibilityHint }
    }
    
    private var customAccessibilityLabel:String? = nil
    private var customAccessibilityHint:String? = nil
    
    @objc private func didUpdateOpenDraftingControllers(_: NSNotification?) {
        let openDrafts = OpenDraftsManager.sharedInstance.openDraftingViewControllers
        setMostRecentDraftTitle(openDrafts.last?.draftTitle, numberOfOpenDrafts: openDrafts.count)
    }
    
    private func setMostRecentDraftTitle(mostRecentDraftTitle:String?, numberOfOpenDrafts:Int) {
        mostRecentDraftView.labelText = mostRecentDraftTitle
        secondDraftView.hidden = numberOfOpenDrafts < 2
        thirdDraftView.hidden = numberOfOpenDrafts < 3
        mostRecentDraftTopConstraint.constant = CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
        intrinsicHeight = numberOfOpenDrafts > 0 ? OpenDraftsIndicatorView.displayedHeight : 0
        
        switch numberOfOpenDrafts {
        case 0:
            customAccessibilityLabel = nil
            customAccessibilityHint = nil
        case 1:
            customAccessibilityLabel = NSLocalizedString("One minimized draft: {title}", comment: "Accessibility")
                .stringByReplacingOccurrencesOfString("{title}", withString: mostRecentDraftTitle ?? "Unknown")
            customAccessibilityHint = NSLocalizedString("Double tap to open", comment: "Accessibility")
        default:
            customAccessibilityLabel = NSLocalizedString("{count} minimized drafts. Most recent: {title}", comment: "Accessibility")
                .stringByReplacingOccurrencesOfString("{count}", withString: NSNumberFormatter().stringFromNumber(numberOfOpenDrafts) ?? String(numberOfOpenDrafts))
                .stringByReplacingOccurrencesOfString("{title}", withString: mostRecentDraftTitle ?? "Unknown")
            customAccessibilityHint = NSLocalizedString("Double tap to select", comment: "Accessibility")
        }
        
        isAccessibilityElement = true
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setMostRecentDraftTitle("Able was I, ere I saw Elba", numberOfOpenDrafts: 2)
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        return pointInside(point, withEvent: event) ? self : nil
    }
    
    class func visibleHeaderHeight(numberOfOpenDrafts numberOfOpenDrafts: Int) -> CGFloat {
        if numberOfOpenDrafts == 0 {
            return 0
        } else {
            return 44 - CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
        }
    }
}
