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
    private var intrinsicHeight:CGFloat = 0 { didSet(old) { if intrinsicHeight != old { invalidateIntrinsicContentSize() } } }
    
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activateConstraints([
            attr(contentView, .Leading) == attr(self, .Leading),
            attr(contentView, .Trailing) == attr(self, .Trailing),
            attr(contentView, .Top) == attr(self, .Top),
            attr(contentView, .Height) == OpenDraftsIndicatorView.displayedHeight
        ])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didUpdateOpenDraftingControllers(_:)), name: OpenDraftsManager.notifications.didUpdateOpenDraftingControllers.rawValue, object: OpenDraftsManager.sharedInstance)
    }
    
    @objc private func didUpdateOpenDraftingControllers(_: NSNotification?) {
        let openDrafts = OpenDraftsManager.sharedInstance.openDraftingViewControllers
        setMostRecentDraftTitle(openDrafts.last?.draftTitle, numberOfOpenDrafts: openDrafts.count)
    }
    
    private func setMostRecentDraftTitle(mostRecentDraftTitle:String?, numberOfOpenDrafts:Int) {
        accessibilityLabel = mostRecentDraftTitle
        mostRecentDraftView.labelText = mostRecentDraftTitle
        secondDraftView.hidden = numberOfOpenDrafts < 2
        thirdDraftView.hidden = numberOfOpenDrafts < 3
        mostRecentDraftTopConstraint.constant = CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
        intrinsicHeight = numberOfOpenDrafts > 0 ? OpenDraftsIndicatorView.displayedHeight : 0
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setMostRecentDraftTitle("Able was I, ere I saw Elba", numberOfOpenDrafts: 2)
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        return pointInside(point, withEvent: event) ? self : nil
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 100, height: intrinsicHeight)
    }
    
    class func visibleHeaderHeight(numberOfOpenDrafts numberOfOpenDrafts: Int) -> CGFloat {
        return 43 - CGFloat(6 + 4 * min(numberOfOpenDrafts - 1, 2))
    }
}
