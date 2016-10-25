/**
 * Copyright 2016 IBM Corp. All Rights Reserved.
 *
 * Licensed under the IBM License, a copy of which may be obtained at:
 *
 * http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?li_formnum=L-DDIN-ADRVKF&popup=y&title=IBM%20IoT%20for%20Automotive%20Sample%20Starter%20Apps
 *
 * You may not use this file except in compliance with the license.
 */
import Foundation
import UIKit
import BMSCore
import BMSPush

class NotificationUtils{
    private init(){}
    static let ALERT_TITLE = "IoT Automotive Car Sharing"
    static let ACTION_OPEN_RESERVATION = "ACTION_OPEN_RESERVATION"
    static let ACTION_OK = "ACTION_OK"
    static let CATEGORY_OPEN_RESERVATION = "CATEGORY_OPEN_RESERVATION"
    static let CATEGORY_OK = "CATEGORY_OK"

    static func setNotification(notifyAt:NSDate, message:String, actionLabel:String, userInfo: [NSObject: AnyObject]){
        let calendar = NSCalendar(identifier:NSCalendarIdentifierGregorian)
        let result = calendar?.compareDate(NSDate(), toDate: notifyAt, toUnitGranularity: .Second)
        if result == NSComparisonResult.OrderedDescending {
               return
        }
        let notification = UILocalNotification()
        notification.timeZone = NSTimeZone.systemTimeZone()
        notification.fireDate = notifyAt
        notification.alertBody = message
        notification.alertAction = actionLabel
        notification.category = NotificationUtils.CATEGORY_OPEN_RESERVATION
        notification.userInfo = userInfo
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    static func cancelNotification(userInfo:Dictionary<String, String>){
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
            if(notification.userInfo != nil && NSDictionary(dictionary: notification.userInfo!).isEqualToDictionary(userInfo)){
                UIApplication.sharedApplication().cancelLocalNotification(notification)
                return
            }
        }
    }
    static func showAlert(description:String, action: UIAlertAction){
        let window = UIApplication.sharedApplication().keyWindow
        let alert = UIAlertController(title: NotificationUtils.ALERT_TITLE, message: description, preferredStyle: .Alert)
        alert.addAction(action)
        window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    static func initRemoteNotification(){
        let bmsClient = BMSClient.sharedInstance
        bmsClient.initializeWithBluemixAppRoute(API.connectedAppURL, bluemixAppGUID: API.connectedAppGUID, bluemixRegion: API.bmRegion)
        bmsClient.defaultRequestTimeout = 10.0

        let openReservationAction = UIMutableUserNotificationAction()
        openReservationAction.identifier = ACTION_OPEN_RESERVATION
        openReservationAction.title = "Open"
        openReservationAction.activationMode = .Foreground
        openReservationAction.destructive = false
        openReservationAction.authenticationRequired = true
        
        let okAction = UIMutableUserNotificationAction()
        okAction.identifier = ACTION_OK
        okAction.title = "OK"
        okAction.activationMode = .Background
        okAction.destructive = false
        okAction.authenticationRequired = false
        
        let openReservationCategory = UIMutableUserNotificationCategory()
        openReservationCategory.identifier = CATEGORY_OPEN_RESERVATION
        openReservationCategory.setActions([openReservationAction, okAction], forContext: .Minimal)
        
        let okCategory = UIMutableUserNotificationCategory()
        okCategory.identifier = CATEGORY_OK
        okCategory.setActions([okAction], forContext: .Minimal)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: Set([openReservationCategory, okCategory])))
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    static func getDeviceId() -> String?{
        let authManager  = BMSClient.sharedInstance.authorizationManager
        let devId = authManager.deviceIdentity.id
        return devId
    }
}