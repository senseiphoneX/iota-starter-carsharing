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
import BMSCore
import BMSSecurity

private var currentContext: AuthenticationContext?
private var currentViewController: UIViewController?
private var loginCanceled = false

// Auth delegate for handling custom challenge
class CustomAuthDelegate : AuthenticationDelegate {
    func onAuthenticationChallengeReceived(authContext: AuthenticationContext, challenge: AnyObject) {
        print("onAuthenticationChallengeReceived")
        currentContext = authContext
        dispatch_async(dispatch_get_main_queue(), {
            currentViewController = self.getCurrentViewController()
        })
        dispatch_async(dispatch_get_main_queue(), {
            self.showLoginAlert()
        })
    }

    func onAuthenticationSuccess(info: AnyObject?) {
        print("onAuthenticationSuccess info = \(info)")
        print("onAuthenticationSuccess ----")
        dispatch_async(dispatch_get_main_queue(), {
            self.dismissInProcessAlert(nil)
        })
    }

    func onAuthenticationFailure(info: AnyObject?) {
        print("onAuthenticationFailure info = \(info)")
        print("onAuthenticationFailure ----")
        dispatch_async(dispatch_get_main_queue(), {
            self.dismissInProcessAlert(self.showLoginFailureAlert)
        })
    }

    private func getViewController() -> UIViewController? {
        var vc: UIViewController?
        if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            vc = topController
        } else {
            let window:UIWindow?? = UIApplication.sharedApplication().delegate?.window
            vc = window!!.rootViewController!
        }
        return vc
    }

    private func getCurrentViewController() -> UIViewController? {
        var cvc: UIViewController?
        let topController = UIApplication.sharedApplication().keyWindow?.rootViewController
        let vvc = (topController as! UINavigationController).visibleViewController

        if vvc is UITabBarController {
            cvc = (vvc as! UITabBarController).selectedViewController
        } else {
            // for example, MobilityStarterApp.CreateReservationViewController
            cvc = vvc
        }
        //print("current view controller: " + NSStringFromClass(cvc!.dynamicType))
        return cvc
    }
    
    private func setMessage(text: String) {
        if currentViewController is MessageViewController  {
            (currentViewController as! MessageViewController).setMessage(text)
        }
    }

    private struct InProcess {
        static var label = UILabel(frame: CGRectMake(0, 0, 180, 100));
        static func setLabel() {
            self.label.center = CGPointMake(200, 280)
            self.label.textAlignment = NSTextAlignment.Center
            self.label.textColor = UIColor.whiteColor()
            self.label.font = UIFont.systemFontOfSize(24)
            self.label.text = "Certifying..."
        }

        static var activeIndicator = UIActivityIndicatorView()
        static func set() {
            self.activeIndicator.frame = CGRectMake(0, 0, 50, 50)
            self.activeIndicator.hidesWhenStopped = false
            self.activeIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
            self.activeIndicator.backgroundColor = UIColor.grayColor();
            self.activeIndicator.startAnimating()
        }
    }

    private var inProcessView = UIView(frame: UIScreen.mainScreen().bounds)
    private func setInProcessView() {
        inProcessView.backgroundColor = UIColor.grayColor()
        inProcessView.alpha = 0.8 // transparency
        InProcess.setLabel()
        inProcessView.addSubview(InProcess.label)
        InProcess.set()
        InProcess.activeIndicator.center = inProcessView.center
        inProcessView.addSubview(InProcess.activeIndicator)
    }

    private func showInProcessAlert() {
        self.setInProcessView()
        getViewController()!.view.addSubview(inProcessView)
    }

    private func dismissInProcessAlert(completion: (()->Void)?) {
        dispatch_async(dispatch_get_main_queue(), {
          self.inProcessView.removeFromSuperview()
        })
        if completion != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.showLoginFailureAlert()
            })
        }
    }

    private func showLoginFailureAlert() {
        var message: String
        if loginCanceled == true {
            message = "Login canceled"
        } else {
            message = "Login failed"
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.setMessage(message)
            currentViewController = nil
        })
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default) {
            action in
            // do nothing
        }
        alertController.addAction(okAction)
        getViewController()!.presentViewController(alertController, animated: true, completion: nil)
    }

    private func showLoginAlert() {
        var usernameTextField:UITextField?
        var passwordTextField:UITextField?
        
        let title = NSLocalizedString("IBM IoT for Automotive", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let okButtonTitle = NSLocalizedString("OK", comment: "")

        let alertController = UIAlertController(title: title, message: "This sample login demonstrates custom authentication capability of Mobile Client Access.\nFor this demo, you can enter any values to connect and use the app.", preferredStyle: .Alert)

        // Add the text field
        alertController.addTextFieldWithConfigurationHandler { textField in
            usernameTextField = textField
            usernameTextField!.placeholder = NSLocalizedString("username", comment: "")
            usernameTextField!.secureTextEntry = false
        }

        // Add the text field for the secure text entry
        alertController.addTextFieldWithConfigurationHandler { textField in
            passwordTextField = textField
            passwordTextField?.placeholder = NSLocalizedString("password", comment: "")
            passwordTextField?.secureTextEntry = true
        }

        if let storedUserID = NSUserDefaults.standardUserDefaults().valueForKey("userID") as? String {
            usernameTextField!.text = storedUserID
        }

        // Create the actions
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            print("The \"Login\" alert's cancel action occurred.")
            loginCanceled = true
            // send dummy data to end authorization process
            currentContext!.submitAuthenticationChallengeAnswer(["username":"", "password":""])
        }

        let okAction = UIAlertAction(title: okButtonTitle, style: .Default) { action in
            print("Submitting auth... username:\(usernameTextField!.text)")
            loginCanceled = false
            dispatch_async(dispatch_get_main_queue(), {
                self.showInProcessAlert()
            })
            currentContext!.submitAuthenticationChallengeAnswer(["username":usernameTextField!.text!, "password":passwordTextField!.text!])
        }

        // Add the actions
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        getViewController()!.presentViewController(alertController, animated: true, completion: nil)
    }
}