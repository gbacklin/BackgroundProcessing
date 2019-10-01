//
//  TableViewController.swift
//  BackgroundFetch
//
//  Created by Gene Backlin on 8/28/19.
//  Copyright © 2019 Gene Backlin. All rights reserved.
//

import UIKit

let kCustomRowCount = 1

class TableViewController: UITableViewController {

    var imageDownloadsInProgress: [NSIndexPath : IconDownloader]?
    var entries: [AppRecord]?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageDownloadsInProgress = [NSIndexPath : IconDownloader]()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTableview(notification:)), name: RefreshUIBackgroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if let parsedEntries = (UIApplication.shared.delegate as! AppDelegate).entries {
//            entries = parsedEntries
//            tableView.reloadData()
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // terminate all pending download connections
        terminateAllDownloads()
    }
    
    func terminateAllDownloads() {
        // terminate all pending download connections
        let allDownloads = imageDownloadsInProgress!.values
        allDownloads.forEach { (iconDownloader) in
            iconDownloader.cancelDownload()
        }
        imageDownloadsInProgress!.removeAll()
    }
    
    // MARK: - Table cell image support
    // -------------------------------------------------------------------------------
    //    startIconDownload:forIndexPath:
    // -------------------------------------------------------------------------------
    func startIconDownload(appRecord: AppRecord, indexPath: NSIndexPath) {
        weak var weakSelf = self
        var iconDownloader: IconDownloader? = imageDownloadsInProgress![indexPath]
        if iconDownloader == nil {
            iconDownloader = IconDownloader()
            iconDownloader?.appRecord = appRecord
            iconDownloader?.completionHandler = {
                if let cell: UITableViewCell = weakSelf!.tableView.cellForRow(at: indexPath as IndexPath) {
                    
                    // Display the newly loaded image
                    cell.imageView?.image = appRecord.appIcon
                    
                    // Remove the IconDownloader from the in progress list.
                    // This will result in it being deallocated.
                    weakSelf!.imageDownloadsInProgress?.removeValue(forKey: indexPath)
                }
            }
            imageDownloadsInProgress![indexPath] = iconDownloader
            iconDownloader?.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //    loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    func loadImagesForOnscreenRows() {
        if entries != nil {
            if Int(entries!.count) > 0 {
                let visiblePaths: [IndexPath] = tableView.indexPathsForVisibleRows!
                for indexPath in visiblePaths {
                    let appRecord: AppRecord = entries![indexPath.row]
                    
                    // Avoid the app icon download if the app already has an icon
                   if appRecord.appIcon == nil {
                        startIconDownload(appRecord: appRecord, indexPath: indexPath as NSIndexPath)
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: - Local Notifications
    
    @objc func refreshTableview(notification: Notification) {
        if let parsedEntries = (UIApplication.shared.delegate as! AppDelegate).entries {
            entries = parsedEntries
            tableView.reloadData()
        }
    }

}

// MARK: - UITableViewDataSource

extension TableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        // if there's no data yet, return enough rows to fill the screen
        if entries != nil {
            count = entries!.count
        } else {
            count = kCustomRowCount
        }

        return count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        var nodeCount = 0
        
        if entries != nil {
            nodeCount = entries!.count
        }
        
        // Configure the cell...

        if nodeCount == 0 && indexPath.row == 0 {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCell(withIdentifier: PlaceholderCellIdentifier, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
            // Leave cells empty if there's no data yet
            if nodeCount > 0 {
                // Set up the cell representing the app
                let appRecord: AppRecord = entries![indexPath.row]
                
                cell.textLabel?.text = appRecord.appName
                cell.detailTextLabel?.text = appRecord.artist
                
                // Only load cached images; defer new downloads until scrolling ends
                if appRecord.appIcon == nil {
                    if tableView.isDragging == false && tableView.isDecelerating == false {
                        startIconDownload(appRecord: appRecord, indexPath: indexPath as NSIndexPath)
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell.imageView?.image = UIImage(named: "Placeholder.png")
                } else {
                    cell.imageView?.image = appRecord.appIcon
                }
            }
        }
        
        return cell
    }
}

// MARK: - UIScrollViewDelegate

extension TableViewController {
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            loadImagesForOnscreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenRows()
    }
}
