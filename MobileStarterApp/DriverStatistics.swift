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

class DriverStatistics {
    var totalDistance : Double?
    var scoring : Scoring?
    var speedPattern : SpeedPattern?
    var roadType : RoadType?
    var timeRange : TimeRange?
    
    class func fromDictionary(array:NSArray) -> [DriverStatistics] {
        var returnArray:[DriverStatistics] = []
        for item in array {
            returnArray.append(DriverStatistics(dictionary: item as! NSDictionary))
        }
        return returnArray
    }
    
    init(dictionary: NSDictionary) {
        totalDistance = dictionary["totalDistance"] as? Double
        if (dictionary["scoring"] != nil) {
            scoring = Scoring(dictionary: dictionary["scoring"] as! NSDictionary)
        }
        if (dictionary["speedPattern"] != nil) {
            speedPattern = SpeedPattern(dictionary: dictionary["speedPattern"] as! NSDictionary)
        }
        if (dictionary["roadType"] != nil) {
            roadType = RoadType(dictionary: dictionary["roadType"] as! NSDictionary)
        }
        if (dictionary["timeRange"] != nil) {
            timeRange = TimeRange(dictionary: dictionary["timeRange"] as! NSDictionary)
        }
    }
}

// MARK: RoadType

class RoadType {
    
    let others_key = "Others/Urban path or alley"
    let totalDistance_key = "totalDistance"
    let urban_key = "Urban-road"
    let secondary_key = "Secondary Extra-urban road/urban primary"
    let highway_key = "Highway/motor way"
    let main_key = "Main extra-urban road/urban-highway"
    let unknown_key = "unknown"
    
    var others: Double?
    var totalDistance : Double?
    var urban: Double?
    var secondary: Double?
    var highway: Double?
    var main: Double?
    var unknown: Double?
    
    class func fromDictionary(array:NSArray) -> [RoadType] {
        var returnArray:[RoadType] = []
        for item in array {
            returnArray.append(RoadType(dictionary: item as! NSDictionary))
        }
        return returnArray
    }
    
    init(dictionary: NSDictionary) {
        others = dictionary[others_key] as? Double
        totalDistance = dictionary[totalDistance_key] as? Double
        urban = dictionary[urban_key]as? Double
        secondary = dictionary[secondary_key] as? Double
        highway = dictionary[highway_key] as? Double
        main = dictionary[main_key] as? Double
        unknown = dictionary[unknown_key] as? Double
    }
    
    func toDictionary() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.others, forKey: others_key)
        dictionary.setValue(self.totalDistance, forKey: totalDistance_key)
        dictionary.setValue(self.urban, forKey: urban_key)
        dictionary.setValue(self.secondary, forKey: secondary_key)
        dictionary.setValue(self.highway, forKey: highway_key)
        dictionary.setValue(self.main, forKey: main_key)
        dictionary.setValue(self.unknown, forKey: unknown_key)
        
        return dictionary
    }
    
}

// MARK: SpeedPattern

class SpeedPattern {
    let mixedSpeed_key = "mixedConditions"
    let totalDistance_key = "totalDistance"
    let steadyFlow_key = "steadyFlow"
    let freeFlow_key = "freeFlow"
    let congestion_key = "congestion"
    let severeCongestion_key = "severeCongestion"
    let unknown_key = "unknown"
    
    var mixedSpeed : Double?
    var totalDistance : Double?
    var steadyFlow : Double?
    var freeFlow : Double?
    var congestion : Double?
    var severeCongestion : Double?
    var unknown : Double?
    
    class func fromDictionary(array:NSArray) -> [SpeedPattern] {
        var returnArray:[SpeedPattern] = []
        for item in array {
            returnArray.append(SpeedPattern(dictionary: item as! NSDictionary))
        }
        return returnArray
    }
    
    init(dictionary: NSDictionary) {
        mixedSpeed = dictionary[mixedSpeed_key] as? Double
        totalDistance = dictionary[totalDistance_key] as? Double
        steadyFlow = dictionary[steadyFlow_key] as? Double
        freeFlow = dictionary[freeFlow_key] as? Double
        congestion = dictionary[congestion_key] as? Double
        severeCongestion = dictionary[severeCongestion_key] as? Double
        unknown = dictionary[unknown_key] as? Double
    }
    
    func toDictionary() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.mixedSpeed, forKey: mixedSpeed_key)
        dictionary.setValue(self.totalDistance, forKey: totalDistance_key)
        dictionary.setValue(self.steadyFlow, forKey: steadyFlow_key)
        dictionary.setValue(self.freeFlow, forKey: freeFlow_key)
        dictionary.setValue(self.congestion, forKey: congestion_key)
        dictionary.setValue(self.severeCongestion, forKey: severeCongestion_key)
        dictionary.setValue(self.unknown, forKey: unknown_key)
        
        return dictionary
    }
    
}

// MARK: TimeRange

class TimeRange {
    let morningPeak_key = "morningPeakHours"
    let totalDistance_key = "totalDistance"
    let nightDriving_key = "night"
    let dayDriving_key = "day"
    let eveningPeak_key = "eveningPeakHours"
    
    var morningPeak : Double?
    var totalDistance : Double?
    var nightDriving : Double?
    var dayDriving : Double?
    var eveningPeak : Double?
    
    class func fromDictionary(array:NSArray) -> [TimeRange] {
        var returnArray:[TimeRange] = []
        for item in array {
            returnArray.append(TimeRange(dictionary: item as! NSDictionary))
        }
        return returnArray
    }
    
    init(dictionary: NSDictionary) {
        morningPeak = dictionary[morningPeak_key] as? Double
        totalDistance = dictionary[totalDistance_key] as? Double
        nightDriving = dictionary[nightDriving_key] as? Double
        dayDriving = dictionary[dayDriving_key] as? Double
        eveningPeak = dictionary[eveningPeak_key] as? Double
    }
    
    func toDictionary() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.morningPeak, forKey: morningPeak_key)
        dictionary.setValue(self.totalDistance, forKey: totalDistance_key)
        dictionary.setValue(self.nightDriving, forKey: nightDriving_key)
        dictionary.setValue(self.dayDriving, forKey: dayDriving_key)
        dictionary.setValue(self.eveningPeak, forKey: eveningPeak_key)
        
        return dictionary
    }
}
