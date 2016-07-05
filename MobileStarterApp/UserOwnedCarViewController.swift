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
    var location: CLLocationCoordinate2D?
    
    var startedDriving: Bool = false
    var carData: CarData?
    
    var reservationId: String?
    var reservations: [ReservationsData]?
    
    var pickupTime: Double?
    var dropoffTime: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.tabBarController?.tabBar.hidden = false
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = .Follow
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.titleLabel.text = "Preparing for Your Drive..."

        self.initiateCar()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude), span: MKCoordinateSpanMake(0.05, 0.05)), animated: true)
        
        if (self.startedDriving) {
            self.titleLabel.text = "Speed: \(max(0, newLocation.speed * 60 * 60 / 1000)) km/h"
        }
    }
    
    func initiateCar() {
        let lat = locationManager.location?.coordinate.latitude
        let lng = locationManager.location?.coordinate.longitude
        
        if (lat == nil || lng == nil) {
            API.doHandleError("Location Required", message: "Cannot get the current location. Check setting of Location Services.", moveToRoot: true)
            return
        }
        
        let carInfo: NSDictionary = [
            "deviceID": ViewController.mobileAppDeviceId,
            "name": "User owened car",
            "model": [
                "stars": 5,
                "makeModel": "User's device",
                "year": 2016,
                "mileage": 0,
                "thumbnailURL": "\(API.connectedAppURL)/images/car_icon.png",
                "hourlyRate": 0,
                "dailyRate": 0
            ],
            "distance": 0,
            "lat": lat!, "lng": lng!];
        
        self.carData = CarData.init(dictionary: carInfo)
        
        let url = NSURL(string: API.reservation)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let carId = carData!.deviceID!
        
        self.pickupTime = NSDate().timeIntervalSince1970
        self.dropoffTime = NSDate().timeIntervalSince1970 + 3600
        
        var params = "carId=\(carId)&pickupTime=\(self.pickupTime!)&dropOffTime=\(self.dropoffTime!)"
        if let deviceId = NotificationUtils.getDeviceId() {
            params += "&deviceId=\(deviceId)"
        }
        
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        API.doRequest(request, callback: reserveCarCallback)
    }
    
    @IBAction func startedDriving(sender: AnyObject) {
        if (!startedDriving) {
            startedDriving = true
            ViewController.startDrive(self.carData!.deviceID!)
            drivingButton.setBackgroundImage(UIImage(named: "endDriving"), forState: UIControlState.Normal)
        } else {
            startedDriving = false
            completeReservation(self.reservationId!, alreadyTaken: false)
            drivingButton.setBackgroundImage(UIImage(named: "startDriving"), forState: UIControlState.Normal)
        }
        
    }
    
    func getReservations() {
        let url = NSURL(string: API.reservations)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        API.doRequest(request) { (response, jsonArray) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.reservations = ReservationsData.fromDictionary(jsonArray)
                
                for reservation in self.reservations! {
                    if (reservation.carId == ViewController.mobileAppDeviceId) {
                        if(reservation.status == "driving"){
                            self.completeReservation(reservation._id!, alreadyTaken: true)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.initiateCar()
                            })
                        }else{
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
        
        let carData = self.carData!
        let trip_id = ViewController.getTripId(carData.deviceID);
        if(trip_id != nil){
            // bind this trip to this reservation
            parm["trip_id"] = trip_id
        }
        
        if let data = try? NSJSONSerialization.dataWithJSONObject(parm, options:NSJSONWritingOptions(rawValue: 0)) as NSData? {
            request.HTTPBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(data!.length)", forHTTPHeaderField: "Content-Length")
        }
        
        API.doRequest(request) { (httpResponse, jsonArray) -> Void in
            let statusCode = httpResponse.statusCode
            let reservationType = "dropoff"
            
            var title = ""
            var message = ""
            
            switch statusCode {
            case 200:
                title = "Drive completed"
                message = "Please allow at least 30 minutes for the driver behavior data to be analyzed"
                
                ReservationsViewController.userReserved = true
                CarBrowseViewController.userReserved = true
                NotificationUtils.cancelNotification([
                    "reservationId": (carData.deviceID)!,
                    "type": reservationType,
                    "appRoute": API.connectedAppURL,
                    "appGUID": API.connectedAppGUID,
                    "customAuth": API.connectedCustomAuth
                ])
                ViewController.completeDrive(carData.deviceID);
                // reserve for the next trip
                self.initiateCar();
                break
            default:
                title = "Something went wrong."
            }
            
            if (!alreadyTaken) {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                
                let okAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                    alert.removeFromParentViewController()
                }
                alert.addAction(okAction)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
        }
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
        var title = ""
        
        switch statusCode {
        case 200:
            self.reservationId = ((jsonArray[0]["reservationId"])!) as! String
            
            self.titleLabel.text = "Press Start Driving when ready"
            break
        case 409:
            title = "Car already taken"
            getReservations()
            break
        case 404:
            title = "Car is not available"
            break
        default:
            self.titleLabel.text = "Something Went Wrong."
        }
    }
}