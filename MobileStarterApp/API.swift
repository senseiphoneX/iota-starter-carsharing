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

import CoreLocation
import UIKit
import BMSCore
import BMSSecurity

struct API {
    
    static var connectedAppURL = "https://iota-starter-server.mybluemix.net"
    static var connectedAppGUID = ""
    static var connectedCustomAuth = "" // non-MCA server
    static var bmRegion = BMSClient.REGION_US_SOUTH
    static var customRealm = "custauth"
    
    static var carsNearby = "\(connectedAppURL)/user/carsnearby"
    static var reservation = "\(connectedAppURL)/user/reservation"
    static var reservations = "\(connectedAppURL)/user/activeReservations"
    static var carControl = "\(connectedAppURL)/user/carControl"
    static var driverStats = "\(connectedAppURL)/user/driverInsights/statistics"
    static var trips = "\(connectedAppURL)/user/driverInsights"
    static var tripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors"
    static var latestTripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors/latest"
    static var tripRoutes = "\(connectedAppURL)/user/triproutes"
    static var credentials = "\(connectedAppURL)/user/device/credentials"
    
    static func delegateCustomAuthHandler() -> Void {
        let delegate = CustomAuthDelegate()
        let mcaAuthManager = MCAAuthorizationManager.sharedInstance
        
        do {
            try mcaAuthManager.registerAuthenticationDelegate(delegate, realm: customRealm)
            print("CustomeAuthDelegate was registered")
        } catch {
            print("error with register: \(error)")
        }
        return
    }
    
    static func doInitialize() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let appRoute = userDefaults.valueForKey("appRoute") as? String,
            let appGUID = userDefaults.valueForKey("appGUID") as? String,
            let customAuth = userDefaults.valueForKey("customAuth") as? String {
            connectedAppURL = appRoute
            connectedAppGUID = appGUID
            connectedCustomAuth = customAuth
        }
        if connectedCustomAuth == "true" {
            print("initialize and set up MCA")
            BMSClient.sharedInstance.initializeWithBluemixAppRoute(connectedAppURL, bluemixAppGUID: connectedAppGUID, bluemixRegion: bmRegion)
            BMSClient.sharedInstance.authorizationManager = MCAAuthorizationManager.sharedInstance
            delegateCustomAuthHandler()
        } else {
            print("non-MCA server")
        }
    }
    
    static func login(requestAfterLogin: NSMutableURLRequest?, callback: ((NSHTTPURLResponse, [NSDictionary]) -> Void)?){
        let customResourceURL = BMSClient.sharedInstance.bluemixAppRoute! + "/user/login"
        let request = Request(url: customResourceURL, method: HttpMethod.GET)
        
        print("get to /user/login")
        let callBack:BmsCompletionHandler = {(response: Response?, error: NSError?) in
            if error == nil {
                print ("response :: \(response?.responseText), no error")
                if let newRequest = requestAfterLogin {
                    self.doRequest(newRequest, callback: callback)
                } else {
                    print ("error:: \(error.debugDescription)")
                }
            }
        }
        request.sendWithCompletionHandler(callBack)
    }
   
    static func handleError(error: NSError) {
        doHandleError("Communication Error", message: "\(error)", moveToRoot: true)
    }
    
    static func handleServerError(data:NSData, response: NSHTTPURLResponse) {
        let responseString = String(data: data, encoding: NSUTF8StringEncoding)
        let statusCode = response.statusCode
        doHandleError("Server Error", message: "Status Code: \(statusCode) - \(responseString!)", moveToRoot: false)
    }
    
    static func doHandleError(title:String, message: String, moveToRoot: Bool) {
        var vc: UIViewController?
        if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            vc = topController
        } else {
            let window:UIWindow?? = UIApplication.sharedApplication().delegate?.window
            vc = window!!.rootViewController!
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
            alert.removeFromParentViewController()
            if(moveToRoot){
                UIApplication.sharedApplication().cancelAllLocalNotifications()
                // reset view back to Get Started
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateInitialViewController()! as UIViewController
                UIApplication.sharedApplication().windows[0].rootViewController = controller
            }
        }
        alert.addAction(okAction)
        
        dispatch_async(dispatch_get_main_queue(), {
            vc!.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    static func getUUID() -> String {
        if let uuid = NSUserDefaults.standardUserDefaults().stringForKey("iota-starter-uuid") {
            return uuid
        } else {
            let value = NSUUID().UUIDString
            NSUserDefaults.standardUserDefaults().setValue(value, forKey: "iota-starter-uuid")
            return value
        }
    }
    
    static func doRequest(request: NSMutableURLRequest, callback: ((NSHTTPURLResponse, [NSDictionary]) -> Void)?) {
        print("\(request.HTTPMethod) to \(request.URL!)")
        request.setValue(getUUID(), forHTTPHeaderField: "iota-starter-uuid")
        print("using UUID: \(getUUID())")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {
                print("error=\(error!)")
                handleError(error!)
                return
            }
            
            print("response = \(response!)")
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString!)")
            if !checkAPIVersion(response as! NSHTTPURLResponse) {
                doHandleError("API Version Error", message: "API version between the server and mobile app is inconsistent. Please upgrade your server or mobile app.", moveToRoot: true)
                return;
            }
            
            var jsonArray: [NSMutableDictionary] = []
            do {
                if let tempArray:[NSMutableDictionary] = try NSJSONSerialization.JSONObjectWithData(data!, options: [NSJSONReadingOptions.MutableContainers]) as? [NSMutableDictionary] {
                    jsonArray = tempArray
                } else {
                    if let temp = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSMutableDictionary {
                        jsonArray.append(temp)
                    }
                }
            } catch {
                print("data returned wasn't array of json")
                /*
                 do {
                 if let temp = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                 jsonArray[0] = temp
                 }
                 } catch {
                 print("data returned wasn't json")
                 }
                 */
            }
            
            
            let httpStatus = response as? NSHTTPURLResponse
            print("statusCode was \(httpStatus!.statusCode)")
            
            let statusCode = httpStatus?.statusCode
            
            switch statusCode! {
            case 401:
                self.login(request, callback: callback)
                break
            case 500..<600:
                self.handleServerError(data!, response: (response as? NSHTTPURLResponse)!)
                break
            default:
                callback?((response as? NSHTTPURLResponse)!, jsonArray)
            }
        }
        task.resume()
    }
    static func checkAPIVersion(response:NSHTTPURLResponse)->Bool{
        guard let apiVersion:String = response.allHeaderFields["iota-starter-car-sharing-version"] as? String else{
            print("Server API 1.0 is not supported")
            return false
        }
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let splitedApiVersion = apiVersion.componentsSeparatedByString(".")
        let splitedAppVersion = appVersion.componentsSeparatedByString(".")
        return splitedApiVersion[0] == splitedAppVersion[0]
    }
    
    static func getLocation(lat: Double, lng: Double, label: UILabel) -> Void {
        let gc: CLGeocoder = CLGeocoder()
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        gc.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude), completionHandler: {
            (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if (placemarks!.count > 0) {
                    let placemark = placemarks![0]
                    if placemark.name != nil && placemark.locality != nil {
                        let attrs = [
                            NSFontAttributeName : UIFont.systemFontOfSize(12.0),
                            NSForegroundColorAttributeName : UIColor.blackColor().colorWithAlphaComponent(0.6),
                            NSUnderlineStyleAttributeName : 1,
                        ]
                        let text = "\(placemark.name!), \(placemark.locality!)"
                        let attributedText = NSAttributedString(string: text, attributes: attrs)
                        label.text = attributedText.string
                        label.attributedText = attributedText
                    } else {
                        // TODO: localize
                        label.text = "unknown location"
                    }
                    
                    label.textColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
                    label.highlightedTextColor = UIColor.whiteColor()
                }
            })
        })
    }
}