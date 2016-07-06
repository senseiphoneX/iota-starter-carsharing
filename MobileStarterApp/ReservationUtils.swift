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
import UIKit

class ReservationUtils {
    static let TAB_INDEX_RESERVATION = 1
    static let DEFAULT_PICKUP_TIME_OFFSET:Double = 60*30 // After 20-30 minutes since now
    static let DEFAULT_DROPOFF_TIME_OFFSET:Double = 60*150 // 2 hours reservation
    static let PICKUP_NOTIFICATION_BEFORE:Double = 60*30 // 30 minutes
    static let DROPOFF_NOTIFICATION_BEFORE:Double = 60*30 // 30 minutes


    private init(){}
    
    static func getReservation(reservationId:String, callback:(reservation:ReservationsData)->Void){
        let url = NSURL(string:"\(API.reservation)/\(reservationId)")
        let request = NSMutableURLRequest(URL:url!)
        request.HTTPMethod = "GET"
        API.doRequest(request, callback: {(response, jsonArray)->Void in
            let reservations = ReservationsData.fromDictionary(jsonArray)
            if reservations.count == 1 {
                let reservation = reservations[0]
                callback(reservation: reservation)
            }
        })
    }
    static func resetReservationNotifications(){
        let url = NSURL(string: API.reservations)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        API.doRequest(request) { (response, jsonArray) -> Void in
            let app = UIApplication.sharedApplication()
            app.cancelAllLocalNotifications()
            let reservations = ReservationsData.fromDictionary(jsonArray)
            if reservations.count > 0 {
                for reservation in reservations {
                    if(reservation.status == "active"){
                        ReservationUtils.setPickupNotification(reservation)
                    }else if(reservation.status == "driving"){
                        ReservationUtils.setDropoffNotification(reservation)
                    }
                }
            }
        }
    }
    static func showReservationAlert(label:String, description:String, handler:(action:UIAlertAction)->Void){
        let action = UIAlertAction(title:label, style:.Default, handler:handler)
        NotificationUtils.showAlert(description, action: action)
    }
    static func showReservationPage(reservationId:String){
        ReservationUtils.getReservation(reservationId, callback:{(reservation)->Void in
            dispatch_async(dispatch_get_main_queue(), {
                // Need to modify layout in main thread
                let window = UIApplication.sharedApplication().keyWindow
                // Assume first tabbarcontroller is main ui
                for vc in (window?.rootViewController?.childViewControllers)! {
                    if let tabBarController = vc as? UITabBarController {
                        tabBarController.navigationController?.popToViewController(tabBarController, animated: true)
                        tabBarController.selectedIndex = TAB_INDEX_RESERVATION
                        if reservation.carDetails != nil {
                            let reservationsVC = tabBarController.selectedViewController as! ReservationsViewController
                            reservationsVC.performSegueWithIdentifier("editReservationSegue", sender: reservation)
                        }
                        break
                    }
                }
            })
        })
    }
    static func setPickupNotification(reservation:ReservationsData){
        let pickupTime = NSDate(timeIntervalSince1970:reservation.pickupTime!)
        let cal = NSCalendar(identifier:NSCalendarIdentifierGregorian)
        let result = cal?.compareDate(NSDate(timeIntervalSinceNow:ReservationUtils.PICKUP_NOTIFICATION_BEFORE), toDate: pickupTime, toUnitGranularity: .Second)
        var notifyAt:NSDate
        if result == NSComparisonResult.OrderedDescending {
            notifyAt = NSDate(timeIntervalSinceNow: 20)
        }else{
            notifyAt = NSDate(timeIntervalSince1970:reservation.pickupTime! - ReservationUtils.PICKUP_NOTIFICATION_BEFORE)
        }
        NotificationUtils.setNotification(notifyAt, message: "Pick-up reminder. You are \(Int(ReservationUtils.PICKUP_NOTIFICATION_BEFORE/60)) minutes away from your car pick-up time.", actionLabel: "Open", userInfo: ["reservationId": reservation._id!, "type":"pickup", "appRoute": API.connectedAppURL, "appGUID": API.connectedAppGUID, "customAuth": API.connectedCustomAuth])
    }
    static func setDropoffNotification(reservation:ReservationsData){
        let dropOffTime = NSDate(timeIntervalSince1970:(reservation.dropOffTime)!)
        let cal = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        let result = cal?.compareDate(NSDate(timeIntervalSinceNow:ReservationUtils.DROPOFF_NOTIFICATION_BEFORE), toDate: dropOffTime, toUnitGranularity: .Second)
        var notifyAt:NSDate
        if result == NSComparisonResult.OrderedDescending {
            notifyAt = NSDate(timeIntervalSinceNow: 20)
        }else{
            notifyAt = NSDate(timeIntervalSince1970:(reservation.dropOffTime)! - ReservationUtils.DROPOFF_NOTIFICATION_BEFORE)
        }
        NotificationUtils.setNotification(notifyAt, message: "Drop-off reminder. You are \(Int(ReservationUtils.DROPOFF_NOTIFICATION_BEFORE/60)) minutes away from your car drop-off time.", actionLabel: "Open", userInfo: ["reservationId":reservation._id!, "type":"dropoff", "appRoute": API.connectedAppURL, "appGUID": API.connectedAppGUID, "customAuth": API.connectedCustomAuth])
        
    }
}