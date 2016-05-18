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

struct API {
    
    static var connectedAppURL = "https://iot-automotive-starter.mybluemix.net"
    //static var connectedAppGUID = "b686b8fc-6e12-4ca0-bbee-e0ead628c1fa"
    
    static var carsNearby = "\(connectedAppURL)/user/carsnearby"
    static var reservation = "\(connectedAppURL)/user/reservation"
    static var reservations = "\(connectedAppURL)/user/activeReservations"
    static var carControl = "\(connectedAppURL)/user/carControl"
    static var driverStats = "\(connectedAppURL)/user/driverInsights/statistics"
    static var trips = "\(connectedAppURL)/user/driverInsights"
    static var tripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors"
    static var latestTripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors/latest"
    static var tripRoutes = "\(connectedAppURL)/user/driverInsights/triproutes"
    
    static func doInitialize() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let appRoute = userDefaults.valueForKey("appRoute") as? String {
            connectedAppURL = appRoute
        }
    }
   
    static func handleError(error: NSError) {
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
        
        let alert = UIAlertController(title: "Communcation Error", message: "\(error)", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
            alert.removeFromParentViewController()
            // reset view back to Get Started
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateInitialViewController()! as UIViewController
            UIApplication.sharedApplication().windows[0].rootViewController = controller
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
            
            callback?((response as? NSHTTPURLResponse)!, jsonArray)
        }
        task.resume()
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