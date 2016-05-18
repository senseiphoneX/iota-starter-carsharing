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
 
class BehaviorDuration {
	var start_time : UInt64?
	var end_time : UInt64?

    class func fromDictionary(array:NSArray) -> [BehaviorDuration] {
        var returnArray:[BehaviorDuration] = []
        for item in array {
            returnArray.append(BehaviorDuration(dictionary: item as! NSDictionary))
        }
        return returnArray
    }

	init(dictionary: NSDictionary) {
		start_time = dictionary["start_time"] as? UInt64
		end_time = dictionary["end_time"] as? UInt64
	}
}