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
import CoreLocation
import CocoaMQTT

class ViewController: UIViewController, CLLocationManagerDelegate {
    var mqtt: CocoaMQTT?

    @IBOutlet weak var smarterMobilityLabel : UILabel!
    @IBOutlet weak var specifyServerButton: UIButton!
    @IBOutlet weak var navigator: UINavigationItem!
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var driverBehaviorButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    var locationManager = CLLocationManager()
    
    // drive using my device
    static var mobileAppDeviceId: String = "d" + API.getUUID().substringToIndex(API.getUUID().startIndex.advancedBy(30))
    static var behaviorDemo: Bool = false
    static var deviceCredentials: NSDictionary?
    static var getCredentials: Bool = false
    static var mqttConnected: Bool = false
    static var tripID: String? = nil
    static var userUnlocked: Bool = false
    
    static func startDrive(deviceId: String){
        if(ViewController.reservationForMyDevice(deviceId)){
            ViewController.getCredentials = true // reget credentials to be safe
            ViewController.userUnlocked = true
            if(ViewController.tripID == nil){
                ViewController.tripID = NSUUID().UUIDString
            }
        }
    }

    static func stopDrive(deviceId: String?){
        if(ViewController.reservationForMyDevice(deviceId)){
            ViewController.userUnlocked = false
        }
    }
    
    static func completeDrive(deviceId: String?){
        if(ViewController.reservationForMyDevice(deviceId)){
            ViewController.tripID = nil // clear the tripID
        }
    }
    
    static func getTripId(deviceId: String?) -> String? {
        if(ViewController.reservationForMyDevice(deviceId)){
            return ViewController.tripID
        }
        return nil
    }

    static func reservationForMyDevice(deviceId: String?) -> Bool {
        return ViewController.behaviorDemo && deviceId == ViewController.mobileAppDeviceId
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if (ViewController.behaviorDemo) {
            if (ViewController.getCredentials) {
                let url = NSURL(string: "\(API.credentials)/\(ViewController.mobileAppDeviceId)?owneronly=true")!
                let request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "GET"
                
                API.doRequest(request) { (httpResponse, jsonArray) -> Void in
                    if(jsonArray.count == 0){
                        self._console("Failed to get credential. May exceed free plan limit.")
                        ViewController.behaviorDemo = false;
                        return;
                    }
                    ViewController.deviceCredentials = jsonArray[0]
                    
                    dispatch_sync(dispatch_get_main_queue(), {
                        print("calling mqttsettings")
                        
                        let clientIdPid = "d:\((ViewController.deviceCredentials!.objectForKey("org"))!):\((ViewController.deviceCredentials!.objectForKey("deviceType"))!):\((ViewController.deviceCredentials!.objectForKey("deviceId"))!)"
                        self.mqtt = CocoaMQTT(clientId: clientIdPid, host: "\((ViewController.deviceCredentials!.objectForKey("org"))!).messaging.internetofthings.ibmcloud.com", port: 8883)
                        
                        if let mqtt = self.mqtt {
                            mqtt.username = "use-token-auth"
                            mqtt.password = ViewController.deviceCredentials!.objectForKey("token") as? String
                            mqtt.keepAlive = 90
                            mqtt.delegate = self
                            mqtt.secureMQTT = true
                        }
                        
                        self.mqtt?.connect()

                    })
                }
                
                ViewController.getCredentials = false
            }
            
            if (self.mqtt != nil && ViewController.userUnlocked){
                if(!ViewController.mqttConnected){
                    self.mqtt?.connect()
                }else{
                    sendLocation(newLocation, oldLocation: oldLocation)
                }
            }
        }
    }
    
    func sendLocation(userLocation: CLLocation, oldLocation: CLLocation?) {
        if(mqtt == nil){
            return;
        }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        var data: [String: AnyObject] = [
            "speed": max(0, userLocation.speed * 60 * 60 / 1000),
            "lng": userLocation.coordinate.longitude,
            "lat": userLocation.coordinate.latitude,
            "ts": dateFormatter.stringFromDate(NSDate()),
            "id": ViewController.mobileAppDeviceId,
            "status":  ViewController.tripID != nil ? "Unlocked" : "Locked"
        ]
        if(ViewController.tripID != nil){
            data["trip_id"] = ViewController.tripID
        }else{
            // this trip should be completed, so lock device now
            ViewController.userUnlocked = false;
        }
        
        let stringData: String = jsonToString(data)
        
        mqtt!.publish("iot-2/evt/sensorData/fmt/json", withString: stringData)
    }
    

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.hidden = true
        
        UITabBar.appearance().tintColor = UIColor(red: 65/255, green: 120/255, blue: 190/255, alpha: 1)
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set title border
        let smarterMobilityText = NSAttributedString(
            string: "Smarter Mobility",
            attributes: [NSStrokeColorAttributeName: Colors.dark,
                        NSStrokeWidthAttributeName: -1.0])
        smarterMobilityLabel.attributedText = smarterMobilityText
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        view.backgroundColor = Colors.dark
        
        getStartedButton.layer.borderWidth = 2
        getStartedButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        specifyServerButton.layer.borderWidth = 2
        specifyServerButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        driverBehaviorButton.layer.borderWidth = 2
        driverBehaviorButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        let version: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let build: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        versionLabel.text = "Version: " + version + " Build: " + build
        
        self.navigationController?.navigationBar.barTintColor = Colors.dark
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }
    
    func jsonToString(data: [String: AnyObject]) -> String {
        var temp: String = "{\"d\":{"
        var accum: Int = 0
        
        for i in data {
            if accum == (data.count - 1) {
                temp += "\"\(i.0)\": \"\(i.1)\"}}"
            } else {
                temp += "\"\(i.0)\": \"\(i.1)\", "
            }
            
            accum += 1
        }
        
        return temp
    }
    
    @IBAction func getStartedAction(sender: AnyObject) {
        API.doInitialize()
    }
    
    @IBAction func driverBehaviorDemoAction(sender: AnyObject) {
        API.doInitialize()
        ViewController.behaviorDemo = true
        ViewController.getCredentials = true
        
        switch CLLocationManager.authorizationStatus(){
        case .Denied:
            fallthrough
        case .Restricted:
            fallthrough
        case .NotDetermined:
            let alert = UIAlertController(title: "Location Required", message: "Using your location, you can analyze your driving.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "Setting", style: .Default) { action -> Void in
                let url = NSURL(string: UIApplicationOpenSettingsURLString)!
                UIApplication.sharedApplication().openURL(url)
            }
            let cancelAction = UIAlertAction(title: "Don't Allow", style: .Cancel){action -> Void in
                // do nothing
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        default:
            break
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let target :UITabBarController? = segue.destinationViewController as? UITabBarController
        if(segue.identifier == "showHomeTab"){
            target?.viewControllers!.removeAtIndex(0) // Drive
            ReservationUtils.resetReservationNotifications()
            NotificationUtils.initRemoteNotification()
        } else if(segue.identifier == "showDriveTab"){
            target?.viewControllers!.removeAtIndex(1) // Home
            target?.viewControllers!.removeAtIndex(1) // Reservations
            let app = UIApplication.sharedApplication()
            app.cancelAllLocalNotifications()
        }
    }
}

extension ViewController: CocoaMQTTDelegate {
    
    func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("connected")
        ViewController.mqttConnected = true;
        sendLocation(locationManager.location!, oldLocation: nil) // initial location
        
        //print("didConnectAck \(ack.rawValue)")
        if ack == .ACCEPT {
            print("ACK")
        }
        
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \((message.string)!)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
        _console("mqttDidDisconnect")
        ViewController.mqttConnected = false;
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
}