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
 
class BehaviorTimes {
    var freqStop: [BehaviorDuration]?
    var harshBrake: [BehaviorDuration]?
    var overSpeed: [BehaviorDuration]?
    var freqAcceleration: [BehaviorDuration]?
    var anxiousAcceleration: [BehaviorDuration]?
    var freqBrake: [BehaviorDuration]?
    var tiredDriving: [BehaviorDuration]?
    var accBefTurn: [BehaviorDuration]?
    var brakeOutTurn: [BehaviorDuration]?
    var sharpTurn: [BehaviorDuration]?

    class func fromDictionary(array:NSArray) -> [BehaviorTimes] {
        var returnArray:[BehaviorTimes] = []
        for item in array {
            returnArray.append(BehaviorTimes(dictionary: item as! NSDictionary))
        }
        return returnArray
    }

	init(dictionary: NSDictionary) {
        if (dictionary["FreqStop"] != nil) {
            freqStop = BehaviorDuration.fromDictionary(dictionary["FreqStop"] as! NSArray)
        }
        if (dictionary["HarshBrake"] != nil) {
            harshBrake = BehaviorDuration.fromDictionary(dictionary["HarshBrake"] as! NSArray)
        }
        if (dictionary["OverSpeed"] != nil) {
            overSpeed = BehaviorDuration.fromDictionary(dictionary["OverSpeed"] as! NSArray)
        }
        if (dictionary["FreqAcceleration"] != nil) {
            freqAcceleration = BehaviorDuration.fromDictionary(dictionary["FreqAcceleration"] as! NSArray)
        }
        if (dictionary["AnxiousAcceleration"] != nil) {
            anxiousAcceleration = BehaviorDuration.fromDictionary(dictionary["AnxiousAcceleration"] as! NSArray)
        }
        if (dictionary["FreqBrake"] != nil) {
            freqBrake = BehaviorDuration.fromDictionary(dictionary["FreqBrake"] as! NSArray)
        }
        if (dictionary["TiredDriving"] != nil) {
            tiredDriving = BehaviorDuration.fromDictionary(dictionary["TiredDriving"] as! NSArray)
        }
        if (dictionary["AccBefTurn"] != nil) {
            accBefTurn = BehaviorDuration.fromDictionary(dictionary["AccBefTurn"] as! NSArray)
        }
        if (dictionary["BrakeOutTurn"] != nil) {
            brakeOutTurn = BehaviorDuration.fromDictionary(dictionary["BrakeOutTurn"] as! NSArray)
        }
        if (dictionary["SharpTurn"] != nil) {
            sharpTurn = BehaviorDuration.fromDictionary(dictionary["SharpTurn"] as! NSArray)
        }
	}
}