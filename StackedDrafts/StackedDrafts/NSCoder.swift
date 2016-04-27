//
//  NSCoder.swift
//  StackedDrafts
//
//  Created by Brian Nickel on 4/27/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

import Foundation

private class SafeWrapper : NSObject, NSCoding {
    var value:AnyObject?
    
    init(value:AnyObject?) {
        self.value = value
    }
    
    @objc required convenience init?(coder aDecoder: NSCoder) {
        self.init(value: aDecoder.decodeObjectForKey("value"))
    }
    
    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(value, forKey: "value")
    }
    
    static func wrapArray(array:[AnyObject]) -> AnyObject {
        return array.map(SafeWrapper.init(value:))
    }
    
    static func unwrapArray<T : AnyObject>(array:AnyObject?) -> [T] {
        return (array as? [SafeWrapper])?.flatMap({ $0.value as? T }) ?? []
    }
}

extension NSCoder {
    func encodeSafeArray(array:[AnyObject], forKey key:String) {
        encodeObject(SafeWrapper.wrapArray(array), forKey: key)
    }
    
    func decodeSafeArrayForKey<T: AnyObject>(key:String) -> [T] {
        return SafeWrapper.unwrapArray(decodeObjectForKey(key))
    }
}
