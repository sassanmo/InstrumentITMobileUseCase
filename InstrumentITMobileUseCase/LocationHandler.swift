/*
 Copyright (c) 2017 Oliver Roehrdanz
 Copyright (c) 2017 Matteo Sassano
 Copyright (c) 2017 Christopher Voelker
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 */

import UIKit
import CoreLocation

class LocationHandler {
    
    let locationManager = CLLocationManager()
    var rootViewController : CLLocationManagerDelegate?
    var locationUpdateStarted = false
    
    init() {
        let appDelegate  = UIApplication.shared.delegate!
        var appwindow: UIWindow? = appDelegate.window!
        guard (appwindow != nil) else {
            appwindow = UIWindow(frame: UIScreen.main.bounds)
            return
        }
        if let locationManagerDelegate = appwindow?.rootViewController as? CLLocationManagerDelegate {
            rootViewController = locationManagerDelegate
        }
        locationManager.delegate = rootViewController
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    
    func requestLocationAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }
    
    /// Only latitude & longitude
    func getUsersCurrentLatitudeAndLongitude() -> (CLLocationDegrees, CLLocationDegrees) {
        if CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
            if (locationUpdateStarted == false) {
                locationManager.startUpdatingLocation()
                locationUpdateStarted = true
            }
            let locValue : CLLocationCoordinate2D = locationManager.location!.coordinate
            return (locValue.latitude, locValue.longitude)
        }
        return (CLLocationDegrees(), CLLocationDegrees())
    }
}
