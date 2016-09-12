//
//  SwiftConstraints.swift
//  Stack Exchange
//
//  Created by Brian Nickel on 9/15/14.
//  Copyright (c) 2014 Stack Exchange. All rights reserved.
//

import UIKit

struct PartialConstraint {
    fileprivate let item:AnyObject
    fileprivate let attribute:NSLayoutAttribute
    fileprivate let multiplier:CGFloat?
    fileprivate let constant:CGFloat?
    
    fileprivate func constraintWith(_ partial:PartialConstraint, relation:NSLayoutRelation) -> NSLayoutConstraint {
        assert(multiplier == nil && constant == nil, "Cannot define multiplier or constant on LHS.")
        
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: partial.item, attribute: partial.attribute, multiplier: partial.multiplier ?? 1, constant: partial.constant ?? 0)
    }
    
    fileprivate func constraintWith(_ value:CGFloat, relation:NSLayoutRelation) -> NSLayoutConstraint {
        assert(multiplier == nil && constant == nil, "Cannot define multiplier or constant on LHS.")
        
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: value)
    }
}

func attr(_ item:AnyObject, _ attribute:NSLayoutAttribute) -> PartialConstraint {
    return PartialConstraint(item: item, attribute: attribute, multiplier: nil, constant: nil)
}

func == (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.equal)
}

func >= (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.greaterThanOrEqual)
}

func <= (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.lessThanOrEqual)
}

func == (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.equal)
}

func >= (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.greaterThanOrEqual)
}

func <= (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.lessThanOrEqual)
}

func * (lhs:PartialConstraint, rhs:CGFloat) -> PartialConstraint {
    assert(lhs.constant == nil, "Cannot assign multiplier after constant")
    return PartialConstraint(item: lhs.item, attribute: lhs.attribute, multiplier: (lhs.multiplier != nil ? lhs.multiplier! * rhs : rhs), constant: nil)
}

func * (lhs:CGFloat, rhs:PartialConstraint) -> PartialConstraint {
    return rhs * lhs
}

func / (lhs:PartialConstraint, rhs:CGFloat) -> PartialConstraint {
    return lhs * (1 / rhs)
}

func + (lhs:PartialConstraint, rhs:CGFloat) -> PartialConstraint {
    return PartialConstraint(item: lhs.item, attribute: lhs.attribute, multiplier: lhs.multiplier, constant: (lhs.constant != nil ? lhs.constant! + rhs : rhs))
}

func + (lhs:CGFloat, rhs:PartialConstraint) -> PartialConstraint {
    return rhs + lhs
}

func - (lhs:PartialConstraint, rhs:CGFloat) -> PartialConstraint {
    return lhs + (-rhs)
}

extension UIView {
    
    func constrainToSuperviewEdges(_ inset:UIEdgeInsets = .zero, useLeadingAndTrailing:Bool = true) {
        if let parent = superview {
            
            let leading:NSLayoutAttribute = useLeadingAndTrailing ? .leading : .left
            let trailing:NSLayoutAttribute = useLeadingAndTrailing ? .trailing : .right
            
            translatesAutoresizingMaskIntoConstraints = false
            parent.addConstraints([
                attr(self, .top) == attr(parent, .top) + inset.top,
                attr(self, .bottom) == attr(parent, .bottom) - inset.bottom,
                attr(self, leading) == attr(parent, leading) + inset.left,
                attr(self, trailing) == attr(parent, trailing) - inset.right
                ])
            
        } else {
            assertionFailure("View has no superview")
        }
    }
    
    func constrainToCenterOfSuperview() {
        if let parent = superview {
            
            translatesAutoresizingMaskIntoConstraints = false
            parent.addConstraints([
                attr(self, .centerX) == attr(parent, .centerX),
                attr(self, .centerY) == attr(parent, .centerY)
                ])
            
        } else {
            assertionFailure("View has no superview")
        }
    }
}
