//
//  SwiftConstraints.swift
//  Stack Exchange
//
//  Created by Brian Nickel on 9/15/14.
//  Copyright (c) 2014 Stack Exchange. All rights reserved.
//

import UIKit

struct PartialConstraint {
    private let item:AnyObject
    private let attribute:NSLayoutAttribute
    private let multiplier:CGFloat?
    private let constant:CGFloat?
    
    private func constraintWith(partial:PartialConstraint, relation:NSLayoutRelation) -> NSLayoutConstraint {
        assert(multiplier == nil && constant == nil, "Cannot define multiplier or constant on LHS.")
        
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: partial.item, attribute: partial.attribute, multiplier: partial.multiplier ?? 1, constant: partial.constant ?? 0)
    }
    
    private func constraintWith(value:CGFloat, relation:NSLayoutRelation) -> NSLayoutConstraint {
        assert(multiplier == nil && constant == nil, "Cannot define multiplier or constant on LHS.")
        
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: value)
    }
}

func attr(item:AnyObject, _ attribute:NSLayoutAttribute) -> PartialConstraint {
    return PartialConstraint(item: item, attribute: attribute, multiplier: nil, constant: nil)
}

func == (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.Equal)
}

func >= (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.GreaterThanOrEqual)
}

func <= (lhs:PartialConstraint, rhs:PartialConstraint) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.LessThanOrEqual)
}

func == (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.Equal)
}

func >= (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.GreaterThanOrEqual)
}

func <= (lhs:PartialConstraint, rhs:CGFloat) -> NSLayoutConstraint {
    return lhs.constraintWith(rhs, relation:.LessThanOrEqual)
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
    
    func constrainToSuperviewEdges(inset:UIEdgeInsets = UIEdgeInsetsZero, useLeadingAndTrailing:Bool = true) {
        if let parent = superview {
            
            let leading:NSLayoutAttribute = useLeadingAndTrailing ? .Leading : .Left
            let trailing:NSLayoutAttribute = useLeadingAndTrailing ? .Trailing : .Right
            
            translatesAutoresizingMaskIntoConstraints = false
            parent.addConstraints([
                attr(self, .Top) == attr(parent, .Top) + inset.top,
                attr(self, .Bottom) == attr(parent, .Bottom) - inset.bottom,
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
                attr(self, .CenterX) == attr(parent, .CenterX),
                attr(self, .CenterY) == attr(parent, .CenterY)
                ])
            
        } else {
            assertionFailure("View has no superview")
        }
    }
}
