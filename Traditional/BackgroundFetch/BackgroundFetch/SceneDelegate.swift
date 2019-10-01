//
//  SceneDelegate.swift
//  BackgroundFetch
//
//  Created by Gene Backlin on 8/28/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import UIKit

let TopPaidAppsFeed = "https://rss.itunes.apple.com/api/v1/us/ios-apps/top-paid/all/50/explicit.atom"

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Scene Lifecycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        if let tableViewController: TableViewController = (self.window?.rootViewController as! UINavigationController).topViewController as? TableViewController {
            (UIApplication.shared.delegate as! AppDelegate).tableViewController = tableViewController
        }

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        fetchRSS(url: TopPaidAppsFeed)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        let entries = (UIApplication.shared.delegate as! AppDelegate).entries
        if entries != nil {
            if let controller: TableViewController = (UIApplication.shared.delegate as! AppDelegate).tableViewController {
                controller.entries = entries
                controller.tableView.reloadData()
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        fetchRSS(url: TopPaidAppsFeed)
    }

    // MARK: - Fethching methods
    
    func fetchRSS(url: String) {
        let bundleID: String = Bundle.main.bundleIdentifier!
        let identifier = "\(String(describing: bundleID)).background"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        if let urlObj = URL(string: url) {
            let task = session.downloadTask(with: urlObj)
            print("Starting task...")
            task.resume()
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension SceneDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        debugPrint("didReceive \(data)")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = FileManager.default.contents(atPath: location.path) {
            NotificationCenter.default.post(name: DataReceivedInBackgroundNotification, object: nil, userInfo: ["xml" : data])
        }
        try? FileManager.default.removeItem(at: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
}
