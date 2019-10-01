//
//  Operations.swift
//  BackgroundFetch
//
//  Created by Gene Backlin on 9/27/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import Foundation

class FetchTopAppsOperation: Operation {
    var url: String?
    var delegate: URLSessionDelegate?
    
    override init() {
        super.init()
    }
    
    convenience init(url: String, delegate: URLSessionDelegate?) {
        self.init()
        self.url = url
        self.delegate = delegate
    }

    override func main() {
        debugPrint("FetchTopAppsOperation fetchRSS \(url!)...")

        let bundleID: String = Bundle.main.bundleIdentifier!
        let identifier = "\(String(describing: bundleID)).background"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: config, delegate: delegate!, delegateQueue: OperationQueue())
        
        if let urlObj = URL(string: url!) {
            let task = session.downloadTask(with: urlObj)
            debugPrint("Starting task...")
            task.resume()
        }
    }
}
