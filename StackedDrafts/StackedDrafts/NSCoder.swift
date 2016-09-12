//
//  NSCoder.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/27/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import Foundation

private class SafeWrapper : NSObject, NSCoding {
    var value:Any?
    
    init(value:Any?) {
        self.value = value
    }
    
    @objc required convenience init?(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder.decodeObject(forKey: "value") as! NSCoder)
    }
    
    @objc func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
    }
    
    static func wrapArray(_ array:[Any]) -> Any {
        return array.map(SafeWrapper.init(value:)) as NSArray
    }
    
    static func unwrapArray<T : AnyObject>(_ array:Any?) -> [T] {
        return (array as? [SafeWrapper])?.flatMap({ $0.value as? T }) ?? []
    }
}

extension NSCoder {
    func encodeSafeArray(_ array:[AnyObject], forKey key:String) {
        encode(SafeWrapper.wrapArray(array), forKey: key)
    }
    
    func decodeSafeArrayForKey<T: AnyObject>(_ key:String) -> [T] {
        return SafeWrapper.unwrapArray(decodeObject(forKey: key))
    }
}
