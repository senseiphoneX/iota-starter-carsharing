/**
 * Copyright 2016 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import BMSCore
import BMSPush

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?)
            -> Bool {
                
        UIApplication.sharedApplication().statusBarStyle = .LightContent
                
        if launchOptions != nil {
            let notification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as! UILocalNotification!
            if notification != nil {
                handleReservationNotification(notification)
            }
        }
        return true
    }
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification){
        print("didReceiveLocalNotification")
        handleReservationNotification(notification)
    }
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification")
        if let aps = userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                if let body = alert["body"] as? String {
                    ReservationUtils.showReservationAlert("OK", description: body, handler: {(action:UIAlertAction)->Void in
                        // do nothing
                    })
                }else{
                    ReservationUtils.showReservationAlert("OK", description: "Weather becomes bad", handler: {(action:UIAlertAction)->Void in
                        // do nothing
                    })
                }
            }
        }
    }
    func application (application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData){
        let push = BMSPushClient.sharedInstance
        print("Register Device Token: \(deviceToken)")
        push.registerDeviceToken(deviceToken){(response, statusCode, error) -> Void in
            if error.isEmpty{
                print("Response during device registration: \(response)")
                print("status code during device registration: \(statusCode)")
            }else{
                print("Error during device registration \n - status code: \(statusCode) \n Error: \(error)")
            }
        }
    }
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: ()->Void){
        print("handleActionWithIdentifier forLocalNotification")
        switch(identifier!){
        case NotificationUtils.ACTION_OPEN_RESERVATION:
            handleReservationNotification(notification)
        case NotificationUtils.ACTION_OK:
            // do nothing
            break
        default:
            break
        }
    }
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: (() -> Void)) {
        switch(identifier!){
        case NotificationUtils.ACTION_OPEN_RESERVATION:
            let strPayload = userInfo["payload"] as! String
            do{
                let payload = try NSJSONSerialization.JSONObjectWithData(strPayload.dataUsingEncoding(NSUTF8StringEncoding)!, options: .MutableContainers) as! NSMutableDictionary
                let reservationId = payload["reservationId"] as! String
                ReservationUtils.showReservationPage(reservationId)
            }catch{
                print("payload of remote notification cannot be parsed")
                print(" - \(strPayload)")
            }
        case NotificationUtils.ACTION_OK:
            // do nothing
            break
        default:
            break;
        }
        completionHandler()
    }
    func handleReservationNotification(notification:UILocalNotification){
        let userInfo = notification.userInfo as! [String: String]
        let handler = {(action:UIAlertAction)->Void in
            let reservationId = userInfo["reservationId"]!
            ReservationUtils.showReservationPage(reservationId)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
        switch UIApplication.sharedApplication().applicationState{
        case .Active:
            ReservationUtils.showReservationAlert(notification.alertAction!, description:notification.alertBody!, handler: handler)
        case .Inactive:
            let appRoute = userInfo["appRoute"]!
            let appGUID = userInfo["appGUID"]!
            let customAuth = userInfo["customAuth"]!
            specifyServer(appRoute, appGUID: appGUID, customAuth: customAuth)
            NotificationUtils.cancelNotification(userInfo)
            fallthrough
        case .Background:
            handler(UIAlertAction())
        }
    }
    func specifyServer(appRoute:String, appGUID:String, customAuth:String){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if appRoute != "" {
            userDefaults.setValue(appRoute, forKey: "appRoute")
            userDefaults.setValue(appGUID, forKey: "appGUID")
            if customAuth == "true" {
                userDefaults.setValue(customAuth, forKey: "customAuth")
            } else {
                userDefaults.removeObjectForKey("customAuth")
            }
        }
        userDefaults.synchronize()
        self.window?.rootViewController?.childViewControllers[0].performSegueWithIdentifier("showHomeTab", sender: self)
    }
}

