//
//  SoftwareUpdateManager.swift
//
//  Created by William Henderson on 1/9/15.
//  Copyright (c) 2015 Knock Softwae, Inc. All rights reserved.
//

import Foundation

class SoftwareUpdateManager : NSObject, UIAlertViewDelegate {
    let bucketName = "YOURBUCKETNAME"
    let appName = "YourAppName"

    let manifestUrl = NSURL(string: "https://s3-us-west-2.amazonaws.com/" + bucketName + "/manifest.plist")!
    let minimumUpdateCheckInterval : NSTimeInterval = 60*60*4 // 4 hours
    var lastUpdateCheck : NSDate?

    struct Static {
        static var sharedManager : SoftwareUpdateManager?
    }

    class var sharedManager:SoftwareUpdateManager {
        return Static.sharedManager!
    }

    class func startup() {
        Static.sharedManager = SoftwareUpdateManager()
        Static.sharedManager?.startup()
    }

    func startup() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
        self.checkForUpdateIfNeeded()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func appDidBecomeActive() {
        self.checkForUpdateIfNeeded()
    }

    func checkForUpdateIfNeeded() {
        if (self.lastUpdateCheck != nil && abs(self.lastUpdateCheck!.timeIntervalSinceNow) < self.minimumUpdateCheckInterval ) {
            return
        }

        self.lastUpdateCheck = NSDate()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            let manifestDictionary = NSDictionary(contentsOfURL: self.manifestUrl) as! [String:AnyObject]?
            if (manifestDictionary != nil) {
                let items = manifestDictionary?["items"] as! [AnyObject]?
                let item = items?.last as! [String:AnyObject]?

                let version = item?["metadata"]?["bundle-version"] as! String
                let currentVersion = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String

                if (currentVersion.compare(version, options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending) {
                    // update is available
                    if (UIApplication.sharedApplication().applicationState != UIApplicationState.Active) {
                        let notif = UILocalNotification()
                        notif.alertBody = "An update to " + appName + " is available! Open " + appName + " to upgrade."
                        UIApplication.sharedApplication().presentLocalNotificationNow(notif)
                    }

                    let alert = UIAlertView(title: appName + " Update Available", message: "", delegate: self, cancelButtonTitle: nil, otherButtonTitles: "Update")
                    alert.show()
                }
            }
        })
    }

    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        let itmsURL = String(format: "itms-services://?action=download-manifest&url=%@", self.manifestUrl)
        UIApplication.sharedApplication().openURL(NSURL(string: itmsURL as String)!)
    }

}
