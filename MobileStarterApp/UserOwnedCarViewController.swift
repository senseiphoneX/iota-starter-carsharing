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
import MapKit
import CoreLocation

class UserOwnedCarViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var drivingButton: UIButton!

    let locationManager = CLLocationManager()
    var tripCount: Int = 0
    
    var startedDriving: Bool = false
    var deviceID: String! = ViewController.mobileAppDeviceId
    
    var reservationId: String?
    var reservations: [ReservationsData]?
    
    var pickupTime: Double?
    var dropoffTime: Double?
    
    var alreadyReserved: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        self.locationManager.delegate = self
        self.tabBarController?.tabBar.hidden = false
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.activityType = .AutomotiveNavigation
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = .Follow
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.titleLabel.text = "Press Start Driving when ready"
    }
    @IBAction func onHomeButtonTapped(sender: UIButton) {
        if self.reservationId != nil{
            let cancelAction = UIAlertAction(title: "No", style: .Cancel, handler: {action -> Void in
                // do nothing
            })
            let okAction = UIAlertAction(title: "Yes", style: .Destructive, handler: {action -> Void in
                self.completeReservation(self.reservationId!, alreadyTaken: false)
                self.tabBarController?.navigationController?.popViewControllerAnimated(true)
            })
            self.openAlert("Warning", message: "Going back to the home page would complete your current drive. Are you sure?", actions: [cancelAction, okAction])
        }else{
            self.tabBarController?.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if(!mapView.userLocationVisible){
            mapView.userTrackingMode = .Follow   
        }
        if (self.startedDriving) {
            if(!ViewController.behaviorDemo){
                // get credentials may be failed
                startedDriving = false
                self.completeReservation(self.reservationId!, alreadyTaken: false)
                drivingButton.setBackgroundImage(UIImage(named: "startDriving"), forState: UIControlState.Normal)
                return
            }
            self.titleLabel.text = "Speed: \(max(0, newLocation.speed * 60 * 60 / 1000)) km/h"
            let center = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)
            let circle = MKCircle(centerCoordinate: center, radius: 10);
            circle.title = "location"
            mapView.addOverlay(circle)
            
            self.tripCount += 1
            if(self.tripCount % 10 == 0) {
                renderMapMatchedLocation()
            }
        }
    }
    
    func renderMapMatchedLocation() {
        let trip_id = ViewController.getTripId(self.deviceID)
        if (trip_id == nil){
            return
        }
        let url: NSURL = NSURL(string: "\(API.tripRoutes)/" + (trip_id)! + "?count=20&matchedOnly=true")!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        var stats:[Path] = []
        API.doRequest(request) { (response, jsonArray) -> Void in
            stats = Path.fromDictionary(jsonArray)
            if stats.count > 0 {
                if let stat: Path = stats[0] {
                    dispatch_async(dispatch_get_main_queue(), {
                        for coordinate in stat.coordinates! {
                            let circle = MKCircle(centerCoordinate: CLLocationCoordinate2DMake(coordinate[1].doubleValue!, coordinate[0].doubleValue!), radius: 10);
                            circle.title = "mapMacthed"
                            self.mapView.addOverlay(circle)
                        }
                    })
                }
            }
        }
    }
    
    func reserveCar() {
        // reserve my device as a car
        let url = NSURL(string: API.reservation)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        self.pickupTime = NSDate().timeIntervalSince1970
        self.dropoffTime = NSDate().timeIntervalSince1970 + 3600
        
        let params = "carId=\(self.deviceID!)&pickupTime=\(self.pickupTime!)&dropOffTime=\(self.dropoffTime!)"
        
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        API.doRequest(request, callback: reserveCarCallback)
        
        alreadyReserved = true
    }
    
    @IBAction func startedDriving(sender: AnyObject) {
        if (!startedDriving) {
            self.mapView.removeOverlays(self.mapView.overlays)
            if(ViewController.startDrive(self.deviceID!)){
                self.reserveCar()
                drivingButton.setBackgroundImage(UIImage(named: "endDriving"), forState: UIControlState.Normal)
            }else{
                self.openAlert("Failed to connect to IoT Platform", message:"", actions:nil)
            }
        } else {
            startedDriving = false
            self.completeReservation(self.reservationId!, alreadyTaken: false)
            drivingButton.setBackgroundImage(UIImage(named: "startDriving"), forState: UIControlState.Normal)
        }
        
    }
    
    func useExistingReservation() {
        let url = NSURL(string: API.reservations)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        API.doRequest(request) { (response, jsonArray) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.reservations = ReservationsData.fromDictionary(jsonArray)
                
                for reservation in self.reservations! {
                    if (reservation.carId == ViewController.mobileAppDeviceId) {
                        if(reservation.status == "driving"){
                            // my device is already driving. 
                            // Maybe we should complete it once and restart driving.
                            self.completeReservation(reservation._id!, alreadyTaken: true)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.reserveCar()
                            })
                        } else {
                            // reuse existing active reservation
                            self.startedDriving = true
                            self.reservationId = reservation._id!
                        }
                    }
                }
            })
        }
    }
    
    func completeReservation(reservationId: String, alreadyTaken: Bool) {
        
        let url = NSURL(string: "\(API.reservation)/\(reservationId)")!
        let request = NSMutableURLRequest(URL: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "PUT"
        
        var parm = ["status": "close"]
        
        let trip_id = ViewController.getTripId(self.deviceID);
        if(trip_id != nil){
            // bind this trip to this reservation
            parm["trip_id"] = trip_id
        }
        ViewController.completeDrive(self.deviceID);
        
        if let data = try? NSJSONSerialization.dataWithJSONObject(parm, options:NSJSONWritingOptions(rawValue: 0)) as NSData? {
            request.HTTPBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(data!.length)", forHTTPHeaderField: "Content-Length")
        }
        
        API.doRequest(request) { (httpResponse, jsonArray) -> Void in
            let statusCode = httpResponse.statusCode
            
            var title = ""
            var message = ""
            
            switch statusCode {
            case 200:
                title = "Drive completed"
                message = "Please allow at least 30 minutes for the driver behavior data to be analyzed"
                self.reservationId = nil
                break
            default:
                title = "Something went wrong."
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.titleLabel.text = title
            })
            
            if (!alreadyTaken) {
                self.openAlert(title, message: message, actions: nil)
            }
        }
    }
    
    func openAlert(title: String, message: String, actions: [UIAlertAction]?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        if let _actions:[UIAlertAction] = actions {
            for action in _actions {
                alert.addAction(action)
            }
        }else{
            let okAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                alert.removeFromParentViewController()
            }
            alert.addAction(okAction)
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            UIApplication.sharedApplication().keyWindow?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    func cancelReservation(reservationId: String) {
        let url = NSURL(string: "\(API.reservation)/\(reservationId)")!
        let request = NSMutableURLRequest(URL: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "DELETE"
        
        API.doRequest(request) { (httpResponse, jsonArray) -> Void in
        }
    }
    
    func reserveCarCallback(httpResponse: NSHTTPURLResponse, jsonArray: [NSDictionary]) {
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            // start driving
            self.startedDriving = true
            self.reservationId = ((jsonArray[0]["reservationId"])!) as? String
            break
        case 409:
            self.titleLabel.text = "Car already taken"
            useExistingReservation()
            break
        case 404:
            self.titleLabel.text = "Car is not available"
            break
        default:
            self.titleLabel.text = "Something Went Wrong."
        }
    }
}

extension UserOwnedCarViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer:MKOverlayPathRenderer
        if overlay is MKCircle {
            renderer = MKCircleRenderer(overlay:overlay)
        } else {
            renderer = MKPolylineRenderer(overlay:overlay)
        }
        if (overlay.title! == "location") {
            renderer.fillColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 0.5)
        } else {
            renderer.fillColor = UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)
        }
        return renderer
    }
}
