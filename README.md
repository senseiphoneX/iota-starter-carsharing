# IoT for Automotive Starter Mobile Application
-----
## Overview
This IoT for Automotive Starter will help you get started with the **IoT for Automotive Context Mapping** and **Driver Behavior** services available on **IBM Bluemix** in order to create automotive solutions.

The IoT for Automotive Starter Mobile App is a sample source code for interacting with the IBM IoT for Automotive Starter Server Application, which enables a car-sharing service. Using the mobile app, you can search available cars near you, reserve a car, unlock and then start driving. You can also view your driving score as a part of the service.

This sample source code for IoT for Automotive Starter Mobile App is intended solely for use with an Apple iOS product and intended to be used in conjunction with officially licensed Apple development tools and further customized and distributed under the terms and conditions of your licensed Apple iOS Developer Program or your licensed Apple iOS Enterprise Program.

The sample source code for the companion IoT for Automotive Starter Server App can be found at [ibm-watson-iot/iota-starter-server](https://github.com/ibm-watson-iot/iota-starter-server).

-----
## How to build and run this app

This application source code was developed using Xcode 7.3.  To run this app, follow the stepps below.

1. Install CocoaPods if needed (See [CocoaPods](https://cocoapods.org/) for more information)

   ```$ sudo gem install cocoapods```

2. Clone this repo into your local environment

   ```$ git clone https://github.com/ibm-watson-iot/iota-starter-carsharing```

3. Go to the project folder on the Terminal app

4. ```$ pod install```

5. ```$ open MobileStarterApp.xcworkspace```

6. Set a URL of an instance of **IoT for Automotive Starter Server App** to the _connectedAppURL_ variable in **API.swift** file.

7. Click the run button at the top left of the Xcode UI.

**Note: Please make sure that you are running Xcode 7.3+**

[![](XcodePreview.jpg)](https://www.youtube.com/watch?v=9O5uoPsn0LA "Instructions")  

### (Optional) Setup Push Notifications
You can enable push notifications to the mobile app when the weather at the drop off time of your car reservation becomes bad. Follow the steps below to make the Push Notifications ready for use. See [Push Notifications](https://console.ng.bluemix.net/docs/services/mobilepush/t_push_provider_ios.html) for more information.

1. Register an App ID enabled Push Notifications on [Apple Developer](https://developer.apple.com/) portal

2. Create a development APNs SSL certificate

3. Create a development provisioning profile

4. Setting up APNs on the Bluxmix Push Notifications Dashboard binded to your server application

5. Connect your iOS phone to your Mac

6. Change Bundle Identifier of the Xcode project to your App ID

7. Build and run the mobile app targeting to your iOS phone

8. Tap "Specify Server" button on the mobile app

9. Tap QR code image, then camera function will be launched

10. Open your server app (https://&lt;your-app-route&gt;.mybluemix.net/) by PC browser and scroll down to show a QR code

11. Read the QR code by the mobile app

---
This mobile app contains simple demonstration of Mobile Client Access service. It logins with hardcoded username and password using Mobile Client Access for custom authentication.

* [CustomAuthDelegate.swift](MobileStarterApp/CustomAuthDelegate.swift) onAuthenticationChallengeReceived()  
Call submitAuthenticationChallengeAnswer() with hardcorded username and password.

* [QRCodeReaderViewController.swift](MobileStarterApp/QRCodeReaderViewController.swift) configureVideoCapture()  
Set whether use custom authentication or not in okAction.

* [API.swift](MobileStarterApp/API.swift) doInitialize()  
Initialize the Mobile Client Access client SDK.

See [Configuring the Mobile Client Access client SDK for iOS](https://console.ng.bluemix.net/docs/services/mobileaccess/custom-auth-ios-swift-sdk.html) for more information.

Also need to add and configure Mobile Client Access for custom authentication on IoT for Automotive Starter app server.
See [IoT for Automotive Starter app]( https://github.com/ibm-watson-iot/iota-starter-server).

----
## Report Bugs
If you find a bug, please report it using the [Issues section](https://github.com/ibm-watson-iot/iota-starter-carsharing/issues).

----
## Privacy Notice
The IoT for Automotive Starter app on Bluemix stores your driving history obtained using this Mobile App.

----
## Useful links
[IBM IoT for Automotive](http://www.ibm.com/internet-of-things/iot-industry/iot-automotive)
[IBM Watson Internet of Things](http://www.ibm.com/internet-of-things/)  
[IBM Watson IoT Platform](http://www.ibm.com/internet-of-things/iot-solutions/watson-iot-platform/)   
[IBM Watson IoT Platform Developers Community](https://developer.ibm.com/iotplatform/)
[IBM Bluemix](https://bluemix.net/)  
[IBM Bluemix Documentation](https://www.ng.bluemix.net/docs/)  
[IBM Bluemix Developers Community](http://developer.ibm.com/bluemix)  
