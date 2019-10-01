//
//  AppDelegate.swift
//  BackgroundFetch
//
//  Created by Gene Backlin on 8/28/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import UIKit

let DataReceivedInBackgroundNotification = Notification.Name("DataReceivedInBackgroundNotification")
let DataReceivialScheduledInBackgroundNotification = Notification.Name("DataReceivialScheduledInBackgroundNotification")
let RefreshUIBackgroundNotification = Notification.Name("RefreshUIBackgroundNotification")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // the queue to run our "ParseOperation"
    var queue: OperationQueue?
    
    // the Operation driving the parsing of the RSS feed
    var parser: ParseOperation?
    
    // the AppRecords parsed from the parsing of the RSS feed
    var entries: [AppRecord]?
    
    var tableViewController: TableViewController?
    
    var center: UNUserNotificationCenter?
    
    // MARK: - Application Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        registerNotifications()
        authorizeNotfications()

        return true
    }
                
    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // MARK: - Selector methods

    @objc func backgroundSessionDidReceiveData(notification: Notification) {
        if let userInfo = notification.userInfo {
            weak var weakSelf = self

            if let time = userInfo["time"] {
                DispatchQueue.main.async {
                    weakSelf!.scheduleLocalNotification(center: weakSelf!.center!, timeInterval: 1, title: "Fetching remote data scheduled", message: "Scheduled at: \((time as! Date).description).")
                }
            } else if let xmlData = userInfo["xml"] {
                // create the queue to run our ParseOperation
                weakSelf!.queue = OperationQueue()
                
                // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
                weakSelf!.parser = ParseOperation(data: xmlData as! Data)
                weakSelf!.parser?.errorHandler = {
                    parseError in
                    DispatchQueue.main.async {
                        weakSelf!.handleError(error: parseError!)
                    }
                }
                
                weakSelf!.parser?.completionBlock = {
                    // The completion block may execute on any thread.  Because operations
                    // involving the UI are about to be performed, make sure they execute on the main thread.
                    //
                    DispatchQueue.main.async {
                        if weakSelf!.parser?.appRecordList != nil {
                            weakSelf!.entries = weakSelf!.parser?.appRecordList
                            weakSelf!.scheduleLocalNotification(center: weakSelf!.center!, timeInterval: 1, title: "Parsing XML data completed", message: "\(String(describing: weakSelf!.entries!.count)) items parsed.")
                            NotificationCenter.default.post(name: RefreshUIBackgroundNotification, object: nil, userInfo: nil)
                        }
                    }
                    // we are finished with the queue and our ParseOperation
                    weakSelf!.queue = nil
                }
                weakSelf!.queue?.addOperation(weakSelf!.parser!) // this will start the "ParseOperation"
            }
        }
    }
    
    // MARK: - Notification registration
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundSessionDidReceiveData(notification:)), name: DataReceivedInBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundSessionDidReceiveData(notification:)), name: DataReceivialScheduledInBackgroundNotification, object: nil)
        
    }
    
    // MARK: - Notification authorization
    
    func authorizeNotfications() {
        center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound];
        center!.requestAuthorization(options: options) {
          (granted, error) in
            if !granted {
              print("Something went wrong")
            }
        }
        center!.getNotificationSettings { (settings) in
          if settings.authorizationStatus != .authorized {
            // Notifications not allowed
          }
        }
    }

    // MARK: - Local Notifications
    
    func scheduleLocalNotification(center: UNUserNotificationCenter, timeInterval: TimeInterval, title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval,
        repeats: false)
        
        let identifier = "UYLLocalNotification"
        let request = UNNotificationRequest(identifier: identifier,
                      content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
          if let error = error {
            // Something went wrong
            debugPrint(error.localizedDescription)
          }
        })
    }

    // MARK: - Utility
    
    func handleError(error: Error) {
        let errorMessage = error.localizedDescription
        debugPrint(errorMessage)
    }
    
}

