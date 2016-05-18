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

import Foundation
import MapKit
 
class CarData: NSObject, MKAnnotation {
	var deviceID: String?
	var deviceType: String?
	var lastUpdateTime: Int?
	var lat: Double?
	var lng: Double?
	var name: String?
	var status: String?
	var distance: Int?
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var makeModel: String?
    var year: Int?
    var mileage: Int?
    var availability: String?
    var stars: Int?
    var hourlyRate: Int?
    var dailyRate: Int?
    var thumbnailURL: String?

    class func fromDictionary(array:NSArray) -> [CarData] {
        var returnArray:[CarData] = []
        for item in array {
            returnArray.append(CarData(dictionary: item as! NSDictionary))
        }
        
        return returnArray
    }

	init(dictionary: NSDictionary) {
		deviceID = dictionary["deviceID"] as? String
		deviceType = dictionary["deviceType"] as? String
		lastUpdateTime = dictionary["lastUpdateTime"] as? Int
        if let latValue = dictionary["lat"] as? String {
            lat = Double(latValue)
        } else {
            lat = dictionary["lat"] as? Double
        }
        if let lngValue = dictionary["lng"] as? String {
            lng = Double(lngValue)
        } else {
            lng = dictionary["lng"] as? Double
        }
		name = dictionary["name"] as? String
		status = dictionary["status"] as? String
		distance = dictionary["distance"] as? Int
        
        if let latTemp = lat, longTemp = lng {
            coordinate = CLLocationCoordinate2D(latitude: latTemp, longitude: longTemp)
        } else {
            coordinate = CLLocationCoordinate2D()
        }
        title = name
        
        if (dictionary["model"] != nil) {
            makeModel = dictionary["model"]!["makeModel"] as? String
            year = dictionary["model"]!["year"] as? Int
            mileage = dictionary["model"]!["mileage"] as? Int
            stars = dictionary["model"]!["stars"] as? Int
            hourlyRate = Int((dictionary["model"]!["hourlyRate"] as? Double)!)
            dailyRate = Int((dictionary["model"]!["dailyRate"] as? Double)!)
            thumbnailURL = dictionary["model"]!["thumbnailURL"] as? String
        }
        
        
	}
}