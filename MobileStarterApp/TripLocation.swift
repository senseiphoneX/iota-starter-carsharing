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
 
class TripLocation {
	var start_latitude : Double?
	var start_longitude : Double?
	var end_latitude : Double?
	var end_longitude : Double?
	var behaviors : [TripBehavior]?

    class func fromDictionary(array:NSArray) -> [TripLocation] {
        var returnArray:[TripLocation] = []
        for item in array {
            returnArray.append(TripLocation(dictionary: item as! NSDictionary))
        }
        return returnArray
    }

	init(dictionary: NSDictionary) {
		start_latitude = dictionary["start_latitude"] as? Double
		start_longitude = dictionary["start_longitude"] as? Double
		end_latitude = dictionary["end_latitude"] as? Double
		end_longitude = dictionary["end_longitude"] as? Double
		if (dictionary["behaviors"] != nil) {
            behaviors = TripBehavior.fromDictionary(dictionary["behaviors"] as! NSArray)
        }
	}
}