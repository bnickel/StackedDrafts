//
//  OpenDraftHeaderOverlayView.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/25/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import UIKit

@IBDesignable
class OpenDraftHeaderOverlayView: UIView {
    
    @IBOutlet private var contentView: UIView?
    @IBOutlet private var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadContentView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func loadContentView() {
        UINib(nibName: "OpenDraftHeaderOverlayView.contentView", bundle: NSBundle(forClass: OpenDraftsIndicatorView.self)).instantiateWithOwner(self, options: nil)
        guard let contentView = contentView, let label = label else { preconditionFailure() }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.constrainToSuperviewEdges()
        label.text = labelText
    }
    
    @IBInspectable
    var labelText:String? {
        didSet { label?.text = labelText }
    }
    
    override func prepareForInterfaceBuilder() {
        labelText = "New Question on Retrocomputing"
    }
}