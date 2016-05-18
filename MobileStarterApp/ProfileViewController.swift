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

class ProfileViewController: UIViewController {

    @IBOutlet weak var fetchingLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    
    var stat: DriverStatistics?
    
    var behaviors: [ScoringBehavior] = []
    var timesOfDay: NSDictionary?
    var timesOfDaySortedKeys: [AnyObject]?
    var trafficConditions: NSDictionary?
    var trafficConditionsSortedKeys: [AnyObject]?
    var roadTypes: NSDictionary?
    var roadTypesSortedKeys: [AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.whiteColor()
        headerView.backgroundColor = Colors.dark
        
        getDriverStats()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDriverStats() {
        let url: NSURL = NSURL(string: "\(API.driverStats)")!
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        var stats:[DriverStatistics] = []
        API.doRequest(request) { (response, jsonArray) -> Void in
            stats = DriverStatistics.fromDictionary(jsonArray)
            if stats.count > 0 {
                if let stat: DriverStatistics = stats[0] {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.stat = stat
                        self.behaviors = stat.scoring!.getScoringBehaviors()
                        self.behaviors.sortInPlace({$0.count > $1.count})
                        
                        self.timesOfDay = self.stat?.timeRange?.toDictionary()
                        self.timesOfDay?.setValue(nil, forKey: "totalDistance")
                        self.timesOfDaySortedKeys = (self.timesOfDay! as NSDictionary).keysSortedByValueUsingComparator
                            {
                                ($1 as! NSNumber).compare($0 as! NSNumber)
                            }
                        
                        self.roadTypes = self.stat?.roadType?.toDictionary()
                        self.roadTypes?.setValue(nil, forKey: "totalDistance")
                        self.roadTypesSortedKeys = (self.roadTypes! as NSDictionary).keysSortedByValueUsingComparator
                            {
                                ($1 as! NSNumber).compare($0 as! NSNumber)
                            }
                        
                        self.trafficConditions = self.stat?.speedPattern?.toDictionary()
                        self.trafficConditions?.setValue(nil, forKey: "totalDistance")
                        self.trafficConditionsSortedKeys = (self.trafficConditions! as NSDictionary).keysSortedByValueUsingComparator
                            {
                                ($1 as! NSNumber).compare($0 as! NSNumber)
                            }

                        self.fetchingLabel.text = "Your score is \(Int(round(stat.scoring!.score!))) for \(Int(round(stat.totalDistance!))) miles."
                        
                        self.tableView.reloadData()
                    })
                }
            }
        }
    }
    
    func getValueForIndexPath(indexPath: NSIndexPath, allInfo: Bool) -> (key: String, value: String) {
        var key = ""
        var value = ""
        
        if let _ = self.stat {
            var dict: NSDictionary?
            var totalDistance: Double?
            switch indexPath.section {
            case 0:
                key = self.behaviors[indexPath.row].name!
                value = "\(self.behaviors[indexPath.row].count!)"
                if allInfo {
                    let totalPointsPerBehavior: Double = Double(100 / self.behaviors.count)
                    let pointsForThisBehavior = (self.behaviors[indexPath.row].score! / 100) *  totalPointsPerBehavior
                    let pointsDeducted = Int(round(pointsForThisBehavior - totalPointsPerBehavior))
                    value.appendContentsOf(" (\(pointsDeducted))")
                }
                return (key, value)
            case 1:
                dict = self.timesOfDay
                key = self.timesOfDaySortedKeys![indexPath.row] as! String
                totalDistance = self.stat?.timeRange?.totalDistance
            case 2:
                dict = self.trafficConditions
                key = self.trafficConditionsSortedKeys![indexPath.row] as! String
                totalDistance = self.stat?.speedPattern?.totalDistance
            case 3:
                dict = self.roadTypes
                key = self.roadTypesSortedKeys![indexPath.row] as! String
                totalDistance = self.stat?.roadType?.totalDistance
            default:
                key = "unkonwn"
                value = "unknown"
                return (key, value)
            }
            value = "\(Int(round(((dict?.valueForKey(key))! as! Double) / totalDistance! * 100)))%"
            if allInfo {
                value.appendContentsOf(" (\(Int(round(((dict?.valueForKey(key))! as! Double)))) miles)")
            }
        }
        return (key, value)
    }
}

extension ProfileViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if tableView.indexPathForSelectedRow != nil {
            let selectedIndex = tableView.indexPathForSelectedRow!
            if let cell = tableView.cellForRowAtIndexPath(selectedIndex) {
                let cellInfo = getValueForIndexPath(selectedIndex, allInfo: false)
                cell.textLabel?.text = cellInfo.key
                cell.detailTextLabel?.text = cellInfo.value
            }
        }
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let cellInfo = getValueForIndexPath(indexPath, allInfo: true)
            cell.detailTextLabel!.text = cellInfo.value
        }
    }
}

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let _ = stat {
            return 4
        }
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = stat {
            switch section {
                case 0:
                    return self.behaviors.count
                
                case 1:
                    if let _ = self.timesOfDay {
                        return self.timesOfDay!.count
                    }
                    return 0
            
                case 2:
                    if let _ = self.trafficConditions {
                        return self.trafficConditions!.count
                    }
                    return 0
                        
                case 3:
                    if let _ = self.roadTypes {
                        return self.roadTypes!.count
                    }
                    return 0
                
                default: return 0
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "ProfileViewController-TableViewCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: cellIdentifier)
            cell.contentView.backgroundColor = UIColor.whiteColor()
            cell.detailTextLabel?.textColor = UIColor.blackColor()
            cell.detailTextLabel?.highlightedTextColor = UIColor.whiteColor()
            
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.highlightedTextColor = UIColor.whiteColor()
            
            cell.textLabel?.font = UIFont(name: cell.textLabel!.font.fontName, size: 14)
            cell.detailTextLabel?.font = UIFont(name: cell.textLabel!.font.fontName, size: 14)
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = Colors.dark
            cell.selectedBackgroundView = backgroundView
        }

        let cellInfo = getValueForIndexPath(indexPath, allInfo: false)

        cell.textLabel!.text = cellInfo.key
        cell.detailTextLabel!.text = cellInfo.value

        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 30))
        let label = UILabel(frame: CGRectMake(10,0,320,30))
        label.font = UIFont.boldSystemFontOfSize(20.0)
        label.textColor = Colors.dark
        
        headerView.backgroundColor = UIColor.whiteColor()
        headerView.addSubview(label)
        
        if let _ = stat {
            switch section {
                case 0: label.text = "Behaviors"
                case 1: label.text = "Time of day"
                case 2: label.text = "Traffic condition"
                case 3: label.text = "Type of road"
                default: label.text = ""
            }
        }
        
        return headerView
    }
}