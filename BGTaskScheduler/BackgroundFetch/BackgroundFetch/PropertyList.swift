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
            do {
                result = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: aData!)
            } catch {
                print("Couldn't read file")
            }
        }
        
        return result
    }
    
    class func write(_ filename: NSString, plistDict: NSDictionary) -> Bool {
        let fname: NSString = NSString(format: "%@.plist", filename)
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let bundlePath: NSString = rootPath.appendingPathComponent(fname as String) as NSString
        var aData: Data?
        var isSuccess = false
        
        //let aData: Data = NSKeyedArchiver.archivedData(withRootObject: plistDict)
        do {
            aData = try NSKeyedArchiver.archivedData(withRootObject: plistDict, requiringSecureCoding: false)
            isSuccess = ((try? aData!.write(to: URL(fileURLWithPath: bundlePath as String), options: [.atomic])) != nil)
        } catch {
            print("Couldn't write file")
        }

        return isSuccess
    }
}
