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

class CarBrowseViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var locationIcon: UIButton!    
    
    let locationManager = CLLocationManager()
    var location: CLLocationCoordinate2D?
    var carData: [CarData] = []
    var mapRect: MKMapRect?
    
    static var thumbnailCache = NSMutableDictionary()
    static var jsonIndexCache = NSMutableDictionary()
    
    let pickerData = [
        "Current Location",
        "Tokyo, Japan",
        "MGM Grand, Las Vegas",
        "Mandalay Bay, Las Vegas",
        "Hellabrunn Zoo, Munich, Germany",
        "Nymphenburg Palace, Munich, Germany"
    ]
    var locationData = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 35.709026, longitude: 139.731992),
        CLLocationCoordinate2D(latitude: 36.102118, longitude: -115.165571),
        CLLocationCoordinate2D(latitude: 36.090754, longitude: -115.176670),
        CLLocationCoordinate2D(latitude: 48.0993, longitude: 11.55848),
        CLLocationCoordinate2D(latitude: 48.176656, longitude: 11.553583)
    ]
    
    var locationPicker = UIPickerView()
    var pickerView = UIView()
    
    static var userReserved: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.mapView.delegate = self
        self.tabBarController?.tabBar.hidden = false
        
        // have to do the following to get the map to show the user location
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // also needed to add NSLocationWhenInUseUsageDescription to Info.plist
        // and provide some String that is message to user
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        
        tableView.backgroundColor = UIColor.whiteColor()

        
        headerView.backgroundColor = Colors.dark
        
        setupPicker()
                
        // then need locationManager function below
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if (self.location != nil && CarBrowseViewController.userReserved) {
            clearCarsFromMap(true)
            getCars(self.location!)
        }
        super.viewWillAppear(animated)
    }
    
    func getCars(location: CLLocationCoordinate2D) {
        let lat = location.latitude
        let lng = location.longitude
        
        let url: NSURL = NSURL(string: "\(API.carsNearby)/\(lat)/\(lng)")!
        
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        API.doRequest(request) { (response, jsonArray) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.clearCarsFromMap(true)
                
                self.carData = CarData.fromDictionary(jsonArray)
            
                // add annotations to the map
                self.mapView.addAnnotations(self.carData)
                
                // update label indicating the number of cars
                //TODO: localize this string
                switch self.carData.count {
                case 0: self.titleLabel.text = "There are no cars available."
                case 1: self.titleLabel.text = "There is one car available."
                default: self.titleLabel.text = "There are \(self.carData.count) cars available."
                }
                
                self.carData.sortInPlace({$0.distance < $1.distance})
            
                self.tableView.reloadData()
                
                CarBrowseViewController.userReserved = false
                
                var points: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
                
                for car in self.carData {
                    points.append(CLLocationCoordinate2DMake(car.lat!, car.lng!))
                }
                points.append(self.location!)
                let polyline = MKPolyline(coordinates: UnsafeMutablePointer(points), count: points.count)
                
                self.mapView.addOverlay(polyline)
                self.mapRect = self.mapView.mapRectThatFits(polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(50, 50, 50, 50))
                
                self.mapView.setVisibleMapRect(self.mapRect!, animated: true)
            })
        }
    }
    
    func clearCarsFromMap(carsOnly: Bool) {
        for annotation in mapView.annotations {
            if annotation is CarData {
                mapView.removeAnnotation(annotation)
            } else if !carsOnly {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let targetController: CarDetailsViewController = segue.destinationViewController as! CarDetailsViewController
        
        if let tableCell: UITableViewCell = sender as? UITableViewCell {
            if let selectedIndex: NSIndexPath! = self.tableView.indexPathForCell(tableCell) {
                targetController.car = self.carData[selectedIndex!.item]
            }
        } else if let annotation: MKAnnotation = sender as? MKAnnotation {
            if let car = annotation as? CarData {
                targetController.car = car
            }
        }
    }
    
    @IBAction func exitToCarBrowseScreen(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Needed to jump back to this screen from 
        // CreateReservationViewController (or anything else that needs to reset)
    }
    
    func setupPicker() {
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        pickerView = UIView(frame: CGRectMake(0.0, screenHeight, screenWidth, 260))
        
        locationPicker = UIPickerView(frame: CGRectMake(0.0, 44.0, screenWidth, 216.0))
        locationPicker.delegate = self
        locationPicker.dataSource = self
        locationPicker.showsSelectionIndicator = true
        locationPicker.backgroundColor = UIColor.whiteColor()
        
        let pickerToolbar = UIToolbar()
        pickerToolbar.barStyle = UIBarStyle.BlackTranslucent
        pickerToolbar.tintColor = UIColor.whiteColor()
        pickerToolbar.sizeToFit()
        
        let spaceButtonPicker = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelButtonPicker = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.donePicker))
        pickerToolbar.setItems([cancelButtonPicker, spaceButtonPicker], animated: false)
        pickerToolbar.userInteractionEnabled = true
        
        pickerView.addSubview(pickerToolbar)
        pickerView.addSubview(locationPicker)
    }
    
    @IBAction func pickLocationAction(sender: AnyObject) {
        self.view.addSubview(pickerView)

        UIView.animateWithDuration(0.2, animations: {
            self.pickerView.frame = CGRectMake(0,
                UIScreen.mainScreen().bounds.size.height - 260.0,
                UIScreen.mainScreen().bounds.size.width, 260.0)
        })
    }
    
    func donePicker(sender: UIBarButtonItem) {
        let row = locationPicker.selectedRowInComponent(0)
        
        UIView.animateWithDuration(0.2, animations: {
            self.pickerView.frame = CGRectMake(0,
                UIScreen.mainScreen().bounds.size.height,
                UIScreen.mainScreen().bounds.size.width, 260.0)
        })
        
        let newLocation = locationData[row]
        
        clearCarsFromMap(false)
        getCars(newLocation)
        
        // added code to set the region to display to hopefully
        // overcome problem Eldad seeing when switching location
        let region = MKCoordinateRegion(
            center: newLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        self.mapView.setRegion(region, animated: true)
        
        mapView.centerCoordinate = newLocation
        
        if (row != 0) {
            let centerAnnotation = MKPointAnnotation()
            centerAnnotation.coordinate = newLocation
            centerAnnotation.title = pickerData[row]
            mapView.addAnnotation(centerAnnotation)
        }
        
        self.location = newLocation
    }
    
}

// MARK: - UITableViewDataSource
extension CarBrowseViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return carData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "CarTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? CarTableViewCell
        
        cell?.backgroundColor = UIColor.whiteColor()
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = Colors.dark
        cell?.selectedBackgroundView = backgroundView
        
        let car = carData[indexPath.row]
        
        cell?.carThumbnail.image = nil
        if CarBrowseViewController.thumbnailCache[car.thumbnailURL!] == nil {
            let url = NSURL(string: (car.thumbnailURL)!)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let data = NSData(contentsOfURL: url!)
                
                dispatch_async(dispatch_get_main_queue()) {
                    CarBrowseViewController.thumbnailCache[car.thumbnailURL!] = UIImage(data: data!)
                    cell?.carThumbnail.image = CarBrowseViewController.thumbnailCache[car.thumbnailURL!] as? UIImage
                }
            }
        } else {
            cell?.carThumbnail.image = CarBrowseViewController.thumbnailCache[car.thumbnailURL!] as? UIImage
        }
        
        cell?.carNameLabel.text = car.name
        cell?.carNameLabel.textColor = Colors.dark
        cell?.carNameLabel.highlightedTextColor = UIColor.whiteColor()
        
        //TODO localize and use real data
        if let distance = car.distance {
            cell?.distanceLabel.text = "\(distance) meters away"
            cell?.distanceLabel.textColor = UIColor(red: 78/255, green: 78/255, blue: 78/255, alpha: 100)
            cell?.distanceLabel.highlightedTextColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        }
        
        cell?.ratingLabel.text = String(count: (car.stars)!, repeatedValue: Character("\u{2605}")) + String(count: (5-(car.stars)!), repeatedValue: Character("\u{2606}"))
        
        cell?.ratingLabel.textColor = UIColor(red: 243/255, green: 118/255, blue: 54/255, alpha: 100)
        cell?.ratingLabel.highlightedTextColor = UIColor.whiteColor()
        
        cell?.costLabel.text = "$\((car.hourlyRate)!)/hr, $\((car.dailyRate)!)/day"
        cell?.costLabel.textColor = UIColor.blackColor()
        cell?.costLabel.highlightedTextColor = UIColor.whiteColor()
        
        
        if (indexPath.section==0 && indexPath.row==0) {
            cell?.recommendedImage.image = UIImage(named: "recommended")
        } else {
            cell?.recommendedImage.image = nil
        }
        
        return cell!
    }
}

// MARK: - MKMapViewDelegate
extension CarBrowseViewController: MKMapViewDelegate {
    
    // define what shows on the map for the annotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        if annotation is MKPointAnnotation {
            let tempView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "center")
            tempView.canShowCallout = true
            return tempView
        }
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView!.canShowCallout = true
            let pinImage = UIImage(named: "model-s.png")
            
            // set the size of the image - really??
            let size = CGSize(width: 22, height: 20)
            UIGraphicsBeginImageContext(size)
            pinImage!.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            anView!.image = resizedImage
        } else {
            anView?.annotation = annotation
        }
        return anView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if view.annotation is CarData {
            let carPicked = view.annotation as! CarData
            
            var count = 0
            for car in carData {
                if carPicked.deviceID == car.deviceID {
                    tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: count, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                } else {
                    count += 1
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension CarBrowseViewController: CLLocationManagerDelegate {
    
    // needed to show the user location in map
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]) {
            
            let location = locations.last
            
            let center = CLLocationCoordinate2D(
                latitude: location!.coordinate.latitude,
                longitude: location!.coordinate.longitude)
            
            let region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            
            self.mapView.setRegion(region, animated: true)
            
            self.locationManager.stopUpdatingLocation()
            
            // get cars for the new location
            self.location = center
            self.locationData[0] = center
            getCars(center)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
}

extension CarBrowseViewController: UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row] as String
    }
}

extension CarBrowseViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
}