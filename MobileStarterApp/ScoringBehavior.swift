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

class ScoringBehavior {
	var score : Double?
	var totalTime : Int?
	var count : Int?
    var name : String?

    class func fromDictionary(array:NSArray, name: String) -> [ScoringBehavior] {
        var returnArray:[ScoringBehavior] = []
        for item in array {
            returnArray.append(ScoringBehavior(dictionary: item as! NSDictionary, name: name))
        }
        return returnArray
    }

    init(dictionary: NSDictionary, name: String) {
		score = dictionary["score"] as? Double
		totalTime = dictionary["totalTime"] as? Int
		count = dictionary["count"] as? Int
        self.name = name
	}
}