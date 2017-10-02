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
    
    private var extraBackgroundView = UIView()
    @IBOutlet private var contentView: UIView?
    @IBOutlet private var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadContentView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadContentView() {
        UINib(nibName: "OpenDraftHeaderOverlayView.contentView", bundle: Bundle(for: OpenDraftsIndicatorView.self)).instantiate(withOwner: self, options: nil)
        guard let contentView = contentView, let label = label else { preconditionFailure() }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        extraBackgroundView.backgroundColor = .white
        
        addSubview(extraBackgroundView)
        addSubview(contentView)
        
        extraBackgroundView.constrainToSuperviewEdges()
        contentView.constrainToSuperviewEdges()
        label.text = labelText
    }
    
    var extraSpecialAlpha: CGFloat {
        get {
            return extraBackgroundView.alpha
        }
        set {
            extraBackgroundView.alpha = newValue
            contentView?.alpha = newValue
            label?.alpha = newValue
        }
    }
    
    @IBInspectable
    var labelText: String? {
        didSet { label?.text = labelText }
    }
    
    override func prepareForInterfaceBuilder() {
        labelText = "New Question on Retrocomputing"
    }
}
