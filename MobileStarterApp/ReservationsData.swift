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
 
class ReservationsData {
	var _id : String?
	var _rev : String?
	var type : String?
	var carId : String?
	var pickupTime : Double?
	var dropOffTime : Double?
	var userId : Int?
	var status : String?
	var carDetails : CarData?

    class func fromDictionary(array:NSArray) -> [ReservationsData] {
        var returnArray:[ReservationsData] = []
        for item in array {
            returnArray.append(ReservationsData(dictionary: item as! NSDictionary))
        }
        return returnArray
    }
    
    init(dictionary: NSDictionary) {
        _id = dictionary["_id"] as? String
        _rev = dictionary["_rev"] as? String
        type = dictionary["type"] as? String
        carId = dictionary["carId"] as? String
        pickupTime = Double((dictionary["pickupTime"] as? String)!)
        dropOffTime = Double((dictionary["dropOffTime"] as? String)!)
        userId = dictionary["userId"] as? Int
        status = dictionary["status"] as? String
        
        if (dictionary["carDetails"] != nil) {
            carDetails = CarData(dictionary: dictionary["carDetails"] as! NSDictionary)
        }
    }
}