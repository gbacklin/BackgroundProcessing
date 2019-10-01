//
//  PropertyList.swift
//  PListStorage
//
//  Created by Backlin, Gene on 3/23/15.
//  Copyright (c) 2015 Backlin, Gene. All rights reserved.
//

import UIKit

class PropertyList: NSObject {
   
    class func read(_ filename: NSString) -> NSDictionary? {
        var result: NSDictionary! = nil
        let fname: NSString = NSString(format: "%@.plist", filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let bundlePath: NSString = rootPath.appendingPathComponent(fname as String) as NSString
        
        let aData: Data? = try? Data(contentsOf: URL(fileURLWithPath: bundlePath as String))
        if (aData != nil) {
            //result = NSKeyedUnarchiver.unarchiveObject(with: aData!) as? NSDictionary
            result =  try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self], from: aData!) as? NSDictionary
        }
        
        return result
    }
    
    class func write(_ filename: NSString, plistDict: NSDictionary) -> Bool {
        let fname: NSString = NSString(format: "%@.plist", filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let bundlePath: NSString = rootPath.appendingPathComponent(fname as String) as NSString
        
        //let aData: Data = NSKeyedArchiver.archivedData(withRootObject: plistDict)
        let aData: Data = try! NSKeyedArchiver.archivedData(withRootObject: plistDict, requiringSecureCoding: false)
        
        return ((try? aData.write(to: URL(fileURLWithPath: bundlePath as String), options: [.atomic])) != nil)
    }
}
