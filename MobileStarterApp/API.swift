/**
 * Copyright 2016 IBM Corp. All Rights Reserved.
 *
 * Licensed under the IBM License, a copy of which may be obtained at:
 *
 * http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?li_formnum=L-DDIN-ADRVKF&popup=y&title=IBM%20IoT%20for%20Automotive%20Sample%20Starter%20Apps
 *
 * You may not use this file except in compliance with the license.
 */
import CoreLocation
import UIKit
import BMSCore

let USER_DEFAULTS_KEY_APP_ROUTE = "appRoute"
let USER_DEFAULTS_KEY_PUSH_APP_GUID = "pushAppGuid"
let USER_DEFAULTS_KEY_PUSH_CLIENT_SECRET = "pushClientSecret"
let USER_DEFAULTS_KEY_MCA_TENANT_ID = "mcaTenantId"

struct API {
    static var moveToRootOnError = true
    //static let defaultAppURL = "https://iota-starter-server.mybluemix.net" // Your Bluemix Application URL
    static let defaultPushAppGUID = "" // (Optional) Your Push Notifications Service
    static let defaultPushClientSecret = "" // (Optional) Your Push Notifications Service
    static let defaultMcaTenantId = "" // (Optional) Your Mobile Client Access Service
    static var bmRegion = BMSClient.Region.usSouth
    static var customRealm = "custauth"

    static var connectedAppURL = defaultAppURL
    static var connectedPushAppGUID = defaultPushAppGUID
    static var connectedPushClientSecret = defaultPushClientSecret
    static var connectedMcaTenantId = defaultMcaTenantId
    
    static var carsNearby = "\(connectedAppURL)/user/carsnearby"
    static var reservation = "\(connectedAppURL)/user/reservation"
    static var reservations = "\(connectedAppURL)/user/activeReservations"
    static var carControl = "\(connectedAppURL)/user/carControl"
    static var driverStats = "\(connectedAppURL)/user/driverInsights/statistics"
    static var trips = "\(connectedAppURL)/user/driverInsights"
    static var tripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors"
    static var latestTripBehavior = "\(connectedAppURL)/user/driverInsights/behaviors/latest"
    static var tripRoutes = "\(connectedAppURL)/user/triproutes"
    static var tripAnalysisStatus = "\(connectedAppURL)/user/driverInsights/tripanalysisstatus"
    static var credentials = "\(connectedAppURL)/user/device/credentials"

    static func setURIs(_ appURL: String) {
        carsNearby = "\(appURL)/user/carsnearby"
        reservation = "\(appURL)/user/reservation"
        reservations = "\(appURL)/user/activeReservations"
        carControl = "\(appURL)/user/carControl"
        driverStats = "\(appURL)/user/driverInsights/statistics"
        trips = "\(appURL)/user/driverInsights"
        tripBehavior = "\(appURL)/user/driverInsights/behaviors"
        latestTripBehavior = "\(appURL)/user/driverInsights/behaviors/latest"
        tripRoutes = "\(appURL)/user/triproutes"
        tripAnalysisStatus = "\(appURL)/user/driverInsights/tripanalysisstatus"
        credentials = "\(appURL)/user/device/credentials"
    }

    static func setDefaultServer () {
        connectedAppURL = defaultAppURL
        connectedPushAppGUID = defaultPushAppGUID
        connectedPushClientSecret = defaultPushClientSecret
        connectedMcaTenantId = defaultMcaTenantId
        moveToRootOnError = true
        setURIs(connectedAppURL)
    }

    static func doInitialize() {
        let userDefaults = UserDefaults.standard
        let appRoute = userDefaults.value(forKey: USER_DEFAULTS_KEY_APP_ROUTE) as? String
        let pushAppGUID = userDefaults.value(forKey: USER_DEFAULTS_KEY_PUSH_APP_GUID) as? String
        let pushClientSecret = userDefaults.value(forKey: USER_DEFAULTS_KEY_PUSH_CLIENT_SECRET) as? String
        moveToRootOnError = true
        if(appRoute != nil){
            connectedAppURL = appRoute!
            connectedPushAppGUID = pushAppGUID == nil ? "" : pushAppGUID!
            connectedPushClientSecret = pushClientSecret == nil ? "" : pushClientSecret!
            setURIs(connectedAppURL)
        }
    }

    static func handleError(_ error: NSError) {
        doHandleError("Communication Error", message: "\(error)", moveToRoot: moveToRootOnError)
    }
    
    static func handleServerError(_ data:Data, response: HTTPURLResponse) {
        let responseString = String(data: data, encoding: String.Encoding.utf8)
        let statusCode = response.statusCode
        doHandleError("Server Error", message: "Status Code: \(statusCode) - \(responseString!)", moveToRoot: false)
    }
    
    static func doHandleError(_ title:String, message: String, moveToRoot: Bool) {
        var vc: UIViewController?
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            vc = topController
        } else {
            let window:UIWindow?? = UIApplication.shared.delegate?.window
            vc = window!!.rootViewController!
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            alert.removeFromParentViewController()
            if(moveToRoot){
                UIApplication.shared.cancelAllLocalNotifications()
                // reset view back to Get Started
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateInitialViewController()! as UIViewController
                UIApplication.shared.windows[0].rootViewController = controller
            }
        }
        alert.addAction(okAction)
        
        DispatchQueue.main.async(execute: {
            vc!.present(alert, animated: true, completion: nil)
        })
    }
    
    static func getUUID() -> String {
        if let uuid = UserDefaults.standard.string(forKey: "iota-starter-uuid") {
            return uuid
        } else {
            let value = UUID().uuidString
            UserDefaults.standard.setValue(value, forKey: "iota-starter-uuid")
            return value
        }
    }

    static fileprivate func toJsonArray(_ data: Data) -> [NSMutableDictionary] {
        var jsonArray: [NSMutableDictionary] = []
        do {
            if let tempArray:[NSMutableDictionary] = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.mutableContainers]) as? [NSMutableDictionary] {
                jsonArray = tempArray
            } else {
                if let temp = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSMutableDictionary {
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
        return jsonArray
    }

    static func doRequest(_ request: URLRequest, callback: ((HTTPURLResponse, [NSDictionary]) -> Void)?) {
        var request = request
        print("\(request.httpMethod) to \(request.url!)")
        request.setValue(getUUID(), forHTTPHeaderField: "iota-starter-uuid")
        print("using UUID: \(getUUID())")
        
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            guard error == nil && data != nil else {
                print("error=\(error!)")
                handleError(error! as NSError)
                return
            }

            print("response = \(response!)")
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString!)")
            
            let jsonArray = toJsonArray(data!)

            let httpStatus = response as? HTTPURLResponse
            print("statusCode was \(httpStatus!.statusCode)")

            let statusCode = httpStatus?.statusCode

            switch statusCode! {
                case 500..<600:
                    self.handleServerError(data!, response: (response as? HTTPURLResponse)!)
                    break
                case 200..<400:
                    if !checkAPIVersion(response as! HTTPURLResponse) {
                        doHandleError("API Version Error", message: "API version between the server and mobile app is inconsistent. Please upgrade your server or mobile app.", moveToRoot: true)
                        return;
                    }
                    fallthrough
                default:
                    callback?((response as? HTTPURLResponse)!, jsonArray)
                    moveToRootOnError = false
            }
        }
        task.resume()
    }

    static func checkAPIVersion(_ response:HTTPURLResponse)->Bool{
        guard let apiVersion:String = response.allHeaderFields["Iota-Starter-Car-Sharing-Version"] as? String else{
            print("Server API 1.0 is not supported")
            return false
        }
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let splitedApiVersion = apiVersion.components(separatedBy: ".")
        let splitedAppVersion = appVersion.components(separatedBy: ".")
        return splitedApiVersion[0] == splitedAppVersion[0]
    }
    
    static func getLocation(_ lat: Double, lng: Double, label: UILabel) -> Void {
        let gc: CLGeocoder = CLGeocoder()
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        gc.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude), completionHandler: {
            (placemarks, error) -> Void in
            DispatchQueue.main.async(execute: {
                if (placemarks!.count > 0) {
                    let placemark = placemarks![0]
                    if placemark.name != nil && placemark.locality != nil {
                        let attrs = [
                            NSFontAttributeName : UIFont.systemFont(ofSize: 12.0),
                            NSForegroundColorAttributeName : UIColor.black.withAlphaComponent(0.6),
                            NSUnderlineStyleAttributeName : 1,
                        ] as [String : Any]
                        let text = "\(placemark.name!), \(placemark.locality!)"
                        let attributedText = NSAttributedString(string: text, attributes: attrs)
                        label.text = attributedText.string
                        label.attributedText = attributedText
                    } else {
                        // TODO: localize
                        label.text = "unknown location"
                    }
                    
                    label.textColor = UIColor.black.withAlphaComponent(0.6)
                    label.highlightedTextColor = UIColor.white
                }
            })
        })
    }
}
