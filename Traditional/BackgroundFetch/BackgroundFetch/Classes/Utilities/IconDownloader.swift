/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Helper object for managing the downloading of a particular app's icon.
 It uses NSURLSession/NSURLSessionDataTask to download the app's icon in the background if it does not
 yet exist and works in conjunction with the RootViewController to manage which apps need their icon.
 */

import UIKit

let kAppIconSize: UInt = 48

// MARK: -

class IconDownloader: NSObject {
    var appRecord: AppRecord?
    var completionHandler: (() -> (Void))?
    var sessionTask: URLSessionDataTask?
    
    // -------------------------------------------------------------------------------
    //    startDownload
    // -------------------------------------------------------------------------------
    func startDownload() {
        if appRecord != nil {
            let urlString = appRecord!.imageURLString
            let request: URLRequest = URLRequest(url: URL(string: urlString!)!)
            weak var weakSelf = self
            
            sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                // in case we want to know the response status code
                // let HTTPStatusCode = (response as! HTTPURLResponse).statusCode
                if error != nil {
                    if (error! as NSError).code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        //
                        abort();
                    }
                } else {
                    OperationQueue.main.addOperation({
                        // Set appIcon and clear temporary data/image
                        let image: UIImage = UIImage(data: data!)!
                        if UInt(image.size.width) != kAppIconSize || UInt(image.size.height) != kAppIconSize {
                            let itemSize: CGSize = CGSize(width: Int(kAppIconSize), height: Int(kAppIconSize))
                            UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                            let imageRect: CGRect = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
                            image.draw(in: imageRect)
                            weakSelf?.appRecord?.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                        } else {
                            weakSelf!.appRecord!.appIcon = image
                        }
                        
                        // call our completion handler to tell our client that our icon is ready for display
                        if weakSelf!.completionHandler != nil {
                            weakSelf!.completionHandler!();
                        }
                    })
                }
            })
        } else {
            print ("appRecord is nil")
        }
        sessionTask?.resume()
    }
    
    // -------------------------------------------------------------------------------
    //    cancelDownload
    // -------------------------------------------------------------------------------
    func cancelDownload() {
        sessionTask?.cancel()
        sessionTask = nil
    }
    
}

