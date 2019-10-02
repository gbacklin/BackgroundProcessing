//
//  SceneDelegate.swift
//  BackgroundFetch
//
//  Created by Gene Backlin on 8/28/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.marizack.BackgroundFetch.refresh"]
// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.marizack.BackgroundFetch.refresh"]


import UIKit
import BackgroundTasks

let TopPaidAppsFeed = "https://rss.itunes.apple.com/api/v1/us/ios-apps/top-paid/all/50/explicit.atom"
let RefreshTaskIdentifier = "com.marizack.BackgroundFetch.refresh"

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var backgroundTask: BGProcessingTask?

    // MARK: - Scene Lifecycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        if let tableViewController: TableViewController = (self.window?.rootViewController as! UINavigationController).topViewController as? TableViewController {
            (UIApplication.shared.delegate as! AppDelegate).tableViewController = tableViewController
        }
        registerLaunchHandlersForBackgroundTasks()

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
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
        scheduleAppRefresh()
    }

    // MARK: - Fethching methods
    
    func fetchRSS(url: String, task: BGProcessingTask?) {
        debugPrint("fetchRSS \(url)...")
        
        backgroundTask = task

        let bundleID: String = Bundle.main.bundleIdentifier!
        let identifier = "\(String(describing: bundleID)).background"
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        if let urlObj = URL(string: url) {
            let downloadTask = session.downloadTask(with: urlObj)
            debugPrint("Starting task...")
            downloadTask.resume()
        }
    }
    
    // MARK: - Register Launch Handlers for Background Tasks
    
    func registerLaunchHandlersForBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: RefreshTaskIdentifier, using: DispatchQueue.global()) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            //If we keep requiredExternalPower = true then it required device is connected to external power.
            self.handleAppRefresh(task: task as! BGProcessingTask)
        }
    }

    // MARK: - Scheduling Tasks
    
    func scheduleAppRefresh() {
        debugPrint("Scheduling App Refresh...")
        BGTaskScheduler.shared.cancelAllTaskRequests()

        //let request = BGAppRefreshTaskRequest(identifier: RefreshTaskIdentifier)
        let request = BGProcessingTaskRequest(identifier: RefreshTaskIdentifier)
        request.requiresNetworkConnectivity = true // Defaults to false.
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60) // Fetch no earlier than 1 minute from now
        do {
            try BGTaskScheduler.shared.submit(request)
            NotificationCenter.default.post(name: DataReceivialScheduledInBackgroundNotification, object: nil, userInfo: ["time" : Date()])
        } catch {
            print("Could not schedule app refresh: \(error)")
            print("Attempting URLSession downloadTask...")
            fetchRSS(url: TopPaidAppsFeed, task: backgroundTask)
        }
    }

    // MARK: - Handling Launch for Tasks

    // Fetch the latest feed entries from server.
    // - BGAppRefreshTask
    func handleAppRefresh(task: BGProcessingTask) {
        debugPrint("Scheduling App Refresh...")
        backgroundTask = task
        
//        task.expirationHandler = {
//            //This Block call by System
//            //Canle your all tak's & queues
//        }
//
//        fetchRSS(url: TopPaidAppsFeed, task: task)

        //task.setTaskCompleted(success: true)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let dataFetchOperation = FetchTopAppsOperation(url: TopPaidAppsFeed, delegate: self)
        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            debugPrint("expirationHandler...")
            queue.cancelAllOperations()
        }
        dataFetchOperation.completionBlock = {
            debugPrint("setTaskCompleted...")
            task.setTaskCompleted(success: true)
        }
        queue.addOperation(dataFetchOperation)
        
        scheduleAppRefresh()
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
            debugPrint("didFinishDownloadingTo \(location)")
            backgroundTask!.setTaskCompleted(success: true)
            NotificationCenter.default.post(name: DataReceivedInBackgroundNotification, object: nil, userInfo: ["xml" : data])
        }
        try? FileManager.default.removeItem(at: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
        backgroundTask!.setTaskCompleted(success: true)
    }
}
