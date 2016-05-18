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

class ViewController: UIViewController {

    @IBOutlet weak var specifyServerButton: UIButton!
    @IBOutlet weak var navigator: UINavigationItem!
    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.hidden = true
        
        UITabBar.appearance().tintColor = UIColor(red: 65/255, green: 120/255, blue: 190/255, alpha: 1)
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.dark
        
        getStartedButton.layer.borderWidth = 2
        getStartedButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        specifyServerButton.layer.borderWidth = 2
        specifyServerButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        self.navigationController?.navigationBar.barTintColor = Colors.dark
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }
    
    @IBAction func getStartedAction(sender: AnyObject) {
        API.doInitialize()
    }
}

