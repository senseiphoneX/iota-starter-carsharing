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

class SpecifyServerViewController: UIViewController {

    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var useDefaultButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "appRoute")
    }

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.backItem?.title = ""
        self.title = "Specify Server"
        

        if let appRoute: String = NSUserDefaults.standardUserDefaults().valueForKey("appRoute") as? String {
            if let url : NSURL = NSURL(string: appRoute) {
                if UIApplication.sharedApplication().canOpenURL(url) {
                    API.doInitialize()
                    performSegueWithIdentifier("goToHomeScreen", sender: self)
                } else {
                    showError("No valid URL found from data provided:\n\n\(appRoute)")
                }
            } else {
                showError("No valid URL found from data provided:\n\n\(appRoute)")
            }
        }
        
        super.viewWillAppear(animated)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Scan Error", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
            alert.removeFromParentViewController()
        }
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func useDefaultAction(sender: AnyObject) {
        API.doInitialize()
    }

    @IBAction func moreInfoAction(sender: AnyObject) {
        let url : NSURL = NSURL(string: "http://www.ibm.com/internet-of-things/iot-industry/iot-automotive/")!
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
