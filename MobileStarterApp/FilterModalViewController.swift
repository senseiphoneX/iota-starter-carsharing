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

class FilterModalViewController: UIViewController {
    
    @IBOutlet weak var pickupTextField: UITextField!
    @IBOutlet weak var dropoffTextField: UITextField!
    
    var pickupDate: NSDate?
    var dropoffDate: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        pickupDate = NSDate()
        dropoffDate = NSDate(timeIntervalSince1970: NSDate().timeIntervalSince1970 + 7200)
        
        pickupTextField.text = dateFormatter.stringFromDate(pickupDate!)
        dropoffTextField.text = dateFormatter.stringFromDate(dropoffDate!)
        
        setupDatePicker()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        super.viewWillAppear(animated)
    }
    
    func setupDatePicker() {
        let datePicker: UIDatePicker = UIDatePicker()
        datePicker.backgroundColor = UIColor.whiteColor()
        datePicker.datePickerMode = UIDatePickerMode.DateAndTime
        datePicker.minuteInterval = 10
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged),
                             forControlEvents: UIControlEvents.ValueChanged)
        
        pickupTextField.inputView = datePicker
        dropoffTextField.inputView = datePicker
        
        let pickerToolbar = UIToolbar()
        pickerToolbar.barStyle = UIBarStyle.BlackTranslucent
        pickerToolbar.tintColor = UIColor.whiteColor()
        pickerToolbar.sizeToFit()
        
        let spaceButtonPicker = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelButtonPicker = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.cancelDatePicker))
        pickerToolbar.setItems([cancelButtonPicker, spaceButtonPicker], animated: false)
        pickerToolbar.userInteractionEnabled = true
        dropoffTextField.inputAccessoryView = pickerToolbar
        pickupTextField.inputAccessoryView = pickerToolbar
    }
    
    func datePickerValueChanged(sender: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        if (pickupTextField.isFirstResponder()) {
            pickupTextField.text = dateFormatter.stringFromDate(sender.date)
            self.pickupDate = sender.date
        } else {
            dropoffTextField.text = dateFormatter.stringFromDate(sender.date)
            self.dropoffDate = sender.date
        }
    }
    
    func cancelDatePicker(sender: UIBarButtonItem) {
        dropoffTextField.resignFirstResponder()
        pickupTextField.resignFirstResponder()
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        CarBrowseViewController.pickupDate = Int((self.pickupDate?.timeIntervalSince1970)!)
        CarBrowseViewController.dropoffDate = Int((self.dropoffDate?.timeIntervalSince1970)!)
        CarBrowseViewController.filtersApplied = true
    }
}