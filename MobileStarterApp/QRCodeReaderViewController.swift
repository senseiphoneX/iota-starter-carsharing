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
import AVFoundation

class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
        
    var objCaptureSession:AVCaptureSession?
    var objCaptureVideoPreviewLayer:AVCaptureVideoPreviewLayer?
    var vwQRCode:UIView?
    var sourceViewController: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.configureVideoCapture()
        self.addVideoPreviewLayer()
        self.initializeQRView()
    }
    
    func configureVideoCapture() {
        let objCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error:NSError?
        let objCaptureDeviceInput: AnyObject!
        do {
            objCaptureDeviceInput = try AVCaptureDeviceInput(device: objCaptureDevice) as AVCaptureDeviceInput
            
        } catch let error1 as NSError {
            error = error1
            objCaptureDeviceInput = nil
        }
        if (error != nil) {
            let alert = UIAlertController(title: "No camera detected",
                  message: "Enter the route to the server", preferredStyle: .Alert)

            // Add the text field for entering the route manually
            var routeTextField: UITextField?

            alert.addTextFieldWithConfigurationHandler { textField in
                routeTextField = textField
                routeTextField?.placeholder = NSLocalizedString("Route", comment: "")
                if let appRoute: String = NSUserDefaults.standardUserDefaults().valueForKey("appRoute") as? String {
                    routeTextField?.text = appRoute
                }
            }

            // Add the text field for entering the GUID manually
            var guidTextField: UITextField?

            alert.addTextFieldWithConfigurationHandler { textField in
                guidTextField = textField
                guidTextField?.placeholder = NSLocalizedString("App GUID", comment: "")
                if let appGUID: String = NSUserDefaults.standardUserDefaults().valueForKey("appGUID") as? String {
                    guidTextField?.text = appGUID
                }
            }


            // Create the actions.
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
                self.navigationController?.popViewControllerAnimated(true)
            }
            
            let okAction = UIAlertAction(title: "OK", style: .Default) { action in
                let appRoute = routeTextField?.text
                let appGUID = guidTextField?.text
                let userDefaults = NSUserDefaults.standardUserDefaults()
                if appRoute != "" {
                    userDefaults.setValue(appRoute, forKey: "appRoute")
                    userDefaults.setValue(appGUID, forKey: "appGUID")
                    // if use customAuth then uncomment setValue and comment out removeObjetForKey
                    //userDefaults.setValue("true", forKey: "customAuth")
                    userDefaults.removeObjectForKey("customAuth")
                }
                userDefaults.synchronize()
                self.navigationController?.popViewControllerAnimated(true)
            }

            // Add the actions.
            alert.addAction(cancelAction)
            alert.addAction(okAction)

            self.presentViewController(alert, animated: true){}
            return
        }
        
        objCaptureSession = AVCaptureSession()
        objCaptureSession?.addInput(objCaptureDeviceInput as! AVCaptureInput)
        let objCaptureMetadataOutput = AVCaptureMetadataOutput()
        objCaptureSession?.addOutput(objCaptureMetadataOutput)
        objCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        objCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    }
    
    func addVideoPreviewLayer() {
        objCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: objCaptureSession)
        objCaptureVideoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        objCaptureVideoPreviewLayer?.frame = view.layer.bounds
        self.view.layer.addSublayer(objCaptureVideoPreviewLayer!)
        objCaptureSession?.startRunning()
    }
    
    func initializeQRView() {
        vwQRCode = UIView()
        vwQRCode?.layer.borderColor = UIColor.redColor().CGColor
        vwQRCode?.layer.borderWidth = 5
        self.view.addSubview(vwQRCode!)
        self.view.bringSubviewToFront(vwQRCode!)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            vwQRCode?.frame = CGRectZero
            return
        }
        let objMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if objMetadataMachineReadableCodeObject.type == AVMetadataObjectTypeQRCode {
            let objBarCode = objCaptureVideoPreviewLayer?.transformedMetadataObjectForMetadataObject(objMetadataMachineReadableCodeObject as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            
            vwQRCode?.frame = objBarCode.bounds;
            
            if objMetadataMachineReadableCodeObject.stringValue != nil {
                let fullString = objMetadataMachineReadableCodeObject.stringValue.componentsSeparatedByString(",")
                
                if fullString[0] == "1" {
                    switch (fullString.count) {
                    case 2:
                        let appRoute = fullString[1]
                        NSUserDefaults.standardUserDefaults().setValue(appRoute, forKey: "appRoute")
                        NSUserDefaults.standardUserDefaults().removeObjectForKey("appGUID")
                        NSUserDefaults.standardUserDefaults().removeObjectForKey("customAuth")
                        break;
                    case 3:
                        let appRoute = fullString[1]
                        let appGUID = fullString[2]
                        NSUserDefaults.standardUserDefaults().setValue(appRoute, forKey: "appRoute")
                        NSUserDefaults.standardUserDefaults().setValue(appGUID, forKey: "appGUID")
                        NSUserDefaults.standardUserDefaults().removeObjectForKey("customAuth")
                        break;
                    case 4:
                        let appRoute = fullString[1]
                        let appGUID = fullString[2]
                        let customAuth = fullString[3]
                        NSUserDefaults.standardUserDefaults().setValue(appRoute, forKey: "appRoute")
                        NSUserDefaults.standardUserDefaults().setValue(appGUID, forKey: "appGUID")
                        NSUserDefaults.standardUserDefaults().setValue(customAuth, forKey: "customAuth")
                        break;
                    default:
                        break;
                    }
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
        navigationController?.popViewControllerAnimated(true)
    }
}