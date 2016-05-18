# IoT for Automotive Starter Mobile Application
-----
## Overview
This IoT for Automotive Starter will help you get started with the **IoT for Automotive Context Mapping** and **Driver Behavior** services available on **IBM Bluemix** in order to create automotive solutions.

The IoT for Automotive Starter Mobile App is a sample source code for interacting with the IBM IoT for Automotive Starter Server Application, which enables a car-sharing service. Using the mobile app, you can search available cars near you, reserve a car, unlock and then start driving. You can also view your driving score as a part of the service.

This sample source code for IoT for Automotive Starter Mobile App is intended solely for use with an Apple iOS product and intended to be used in conjunction with officially licensed Apple development tools and further customized and distributed under the terms and conditions of your licensed Apple iOS Developer Program or your licensed Apple iOS Enterprise Program.

The sample source code for the companion IoT for Automotive Starter Server App can be found at [ibm-watson-iot/iota-starter-server](https://github.com/ibm-watson-iot/iota-starter-server).

-----
## How to build and run this app

This application source code was developed using Xcode 7.3.  To run this app, clone this repo and double click on the ```MobileStarterApp.xcodeproj``` file and click the run button at the top left of the Xcode UI.

-----
## What does this app demonstrate?

This mobile app demonstrates the use of **IoT Context Mapping and Driver Behavior** services available on IBM Bluemix.

From the context mapping service, it demonstrates the use of the following API endpoints:

<connectedAppURL>/user/carsnearby
<connectedAppURL>/user/reservation
<connectedAppURL>/user/activeReservations
<connectedAppURL>/user/carControl

From the driver behavior service, it demonstrates the use of the following API endpoints:

<connectedAppURL>/user/driverInsights/statistics
<connectedAppURL>/user/driverInsights
<connectedAppURL>/user/driverInsights/behaviors
<connectedAppURL>/user/driverInsights/triproutes

----
## /user/carsnearby

The ```/user/carsnearby``` endpoint is used to get cars around a position on Earth.  The endpoint works off GPS coordinates in decimal degree format.  Latitude and longitude are passed to the endpoint in the form ```/user/carsnearby/<lat>/<lng>```.  For example, to get the cars near Las Vegas, Nevada, USA, you'd call ```/user/carsnearby/35.709026/-115.165571```

This JSON is converted to a Swift class defined in [CarData.swift](MobileStarterApp/CarData.swift).

This data is used to show car annotations on a map and list of cars in a table.  The code in [CarBrowseViewController.swift](MobileStarterApp/CarBrowseViewController.swift) does this.  The ```getCars()``` function calls ```/user/carsnearby``` parses the JSON and then passes the data to the MKMapView and UITableView.

----
## /user/reservation

The ```/user/reservation``` endpoint is used to reserve a car.  This is a protected endpoint and will require user authentication.  The endpoint requires the device ID of the car along with the start and end date of the reservation, in epoch format, passed as parameters on the URL.  For example, say the device ID, 123456, was returned by the carsnearby endpoint, then the call to reserve it from 12 noon to 1pm GMT time on April 4, 2020 would be ```/user/reservation?carId=123456&pickupTime=1586865600&dropOffTime=1586869200```

There is no JSON returned from this endpoint.

The code in [CreateReservationViewController.swift](MobileStarterApp/CreateReservationViewController.swift) makes a POST call to this endpoint in its ```reserveCarAction()``` function and handles the response in ```reserveCarActionCallback()``` function.

----
## /user/activereservations

The ```/user/activereservations``` endpoint is used to get the user's active reservations.  This is a protected endpoint and will require user authentication.  The endpoint doesn't require any parameters.

This JSON is converted to a Swift class defined in [ReservationsData.swift](MobileStarterApp/ReservationsData.swift).

This data is used to show a list of cars reserved by the user.  The code in [ReservationsViewController.swift](MobileStarterApp/ReservationsViewController.swift) makes a GET call to this endpoint in its ```getReservations()``` function, parses the JSON and tells the UITableView to reload.  Then the UITableViewDataSource extension at the bottom of the file shows the reservations in table cells.

----
## /user/carControl

The ```/user/carControl``` endpoint is used to change properties of the car and currently only the changing of the locked/unlocked state is implemented in this mobile app.  This is a protected endpoint and will require user authentication.  The endpoint requires the reservation ID of the reservation along with a command string passed as parameters on the URL.  For example, say the reservation ID, RRR111222, was returned by the activereservations endpoint, then the call to unlock the car would be ```/user/carControl?reservationId=RRR111222&command=unlock```.  The command can be either "lock" or "unlock".

There is no JSON returned from this endpoint.

The code in [CompleteReservationsViewController.swift](MobileStarterApp/CompleteReservationViewController.swift) makes a POST call to this endpoint and handles the response in its ```unlockCarAction``` function.

----
## /user/driverInsights/statistics

The ```/user/driverInsights/statistics``` endpoint is used to get the score, driving behaviors that contributed to that score, the total miles driven and the conditions in which they were driven for the current user.  This is a protected endpoint and will require authentication.  The endpoint doesn't require any data to be passed to it.

The JSON is converted to many Swift classes defined in [DriverStatistics.swift](MobileStarterApp/DriverStatistics.swift), [Scoring.swift](MobileStarterApp/Scoring.swift), and [ScoringBehavior.swift](MobileStarterApp/ScoringBehavior.swift).  

The code in [ProfileViewController.swift](MobileStarterApp/ProfileViewController.swift) makes a GET call to this endpoint in its ```getDriverStats()``` function, parses the JSON and then tells the UITableView to reload.  The UITableViewDataSource extension at the bottom of the file calls the ```getValueForIndexPath()``` function that converts the raw data into percentages to make it more understandable.

----
## /user/driverInsights

The ```/user/driverInsights``` endpoint is used to get all the trips recorded for the current user.  This is a protected endpoint and will require authentication.  The endpoint doesn't require any data to be passed to it.

This JSON is converted to a couple Swift classes defined in [TripData.swift](MobileStarterApp/TripData.swift).

The code in [TripsTableViewController.swift](MobileStarterApp/TripsTableViewController.swift) makes a GET call to this endpoint in its ```getTrips()``` function, parses the JSON and then tells the UITableView to reload.  The UITableViewDataSource extension at the bottom of the file shows the trips in table cells.

----
## /user/driverInsights/behaviors

The ```/user/driverInsights/behaviors``` endpoint is used to get driver behavior data about a specific trip made by the current user.  This is a protected endpoint and will require authentication.  The endpoint requires a trip UUID to be passed as part of the URL.  For example, say the trip UUID, 123-456-789-TRD, was returned in the trip data provided by the driverInsights endpoint then the call to get info about that trip would be ```/user/driverInsights/behaviors/123-456-789-TRD```.

The JSON is converted to three Swift classes defined in [Trip.swift](MobileStarterApp/Trip.swift), [TripLocation.swift](MobileStarterApp/TripLocation.swift), and [TripBehavior.swift](MobileStarterApp/TripBehavior.swift).  

The code in [LastTripViewController.swift](MobileStarterApp/LastTripViewController.swift) makes a GET call to this endpoint in its ```getDriverBehavior()``` function, parses the JSON, create map annotations for the start and end of the trip, computes the center point of those two GPS coordinates, adds the annotations and centers the MapView.  An internal data structure is created in the ```buildBehaviorData()``` fuction from all the start and end locations for each behavior instance recorded during the trip.  This data structure is used to populate the table view in the UITableViewDataSource extension at the bottom of the file with only the behaviors recorded and place annotations on the map when a table cell is selected in the UITableViewDelegate extension near the bottom of the file.

----
## /user/driverInsights/triproutes

The ```/user/driverInsights/triproutes``` endpoint is used to get all the routes the user has driven through for a trip. The endpoint requires a trip UUID to be passed as part of the URL. For example, say the trip UUID, 123-456-789-TRD, was returned in the trip data provided by the driverInsights endpoint then the call to get info about that trip would be /user/driverInsights/triproutes/123-456-789-TRD.

The GeoJSON returned is described here: [http://geojson.org/](http://geojson.org/)

This GeoJSON is converted to a Swift class defined in [Path.swift](MobileStarterApp/Path.swift).

The code in [TripViewController.swift](MobileStarterApp/TripViewController.swift) makes a GET call to this endpoint in its ```addStartAndEndToMap()``` function, parses the JSON and then tells mapView to add the route as an overlay.

----
## Report Bugs
If you find a bug, please report it using the [Issues section](https://github.com/ibm-watson-iot/iota-starter-carsharing/issues).

----
## Useful links
[IBM IoT for Automotive](http://www.ibm.com/internet-of-things/iot-industry/iot-automotive)
[IBM Watson Internet of Things](http://www.ibm.com/internet-of-things/)  
[IBM Watson IoT Platform](http://www.ibm.com/internet-of-things/iot-solutions/watson-iot-platform/)   
[IBM Watson IoT Platform Developers Community](https://developer.ibm.com/iotplatform/)
[IBM Bluemix](https://bluemix.net/)  
[IBM Bluemix Documentation](https://www.ng.bluemix.net/docs/)  
[IBM Bluemix Developers Community](http://developer.ibm.com/bluemix)  
