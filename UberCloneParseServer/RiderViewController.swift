//
//  RiderViewController.swift
//  UberCloneParseServer
//
//  Created by Manjot S Sandhu on 18/4/20.
//  Copyright © 2020 Manjot S Sandhu. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    let manager = CLLocationManager()
    
    var userLocation : CLLocationCoordinate2D?
    
    var riderRequestActive = true
    
    var driverOnTheWay = false
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var callATuberButton: UIButton!
    
    func displayAlert(title: String, message: String){
        let alertCtrl = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertCtrl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertCtrl, animated: true, completion: nil)
    }
    
    @IBAction func callATuber(_ sender: Any) {
        
        if riderRequestActive {
            
            callATuberButton.setTitle("call a Tuber", for: [])
            riderRequestActive = false
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("userName", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground {
                (objects, error) in
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                        riderRequest.deleteInBackground()
                        
                    }
                    
                }
            }
            
        }else {
            
            if userLocation != nil {
                
                riderRequestActive = true
                
                self.callATuberButton.setTitle("Cancel Uber", for: [])
                
                let riderRequest = PFObject(className: "RiderRequest")
                
                riderRequest["userName"] = PFUser.current()?.username
                riderRequest["location"] = PFGeoPoint(latitude: userLocation!.latitude, longitude: userLocation!.longitude)
                
                riderRequest.saveInBackground {
                    (success, error) in
                    if let error = error {
                        self.callATuberButton.setTitle("Call a Tuber", for: [])
                        self.riderRequestActive = false
                        self.displayAlert(title: "Could not call uber please try again", message: error.localizedDescription)
                    }else{
                        print("Tuber Called")
                        
                    }
                }
            }else{
                self.displayAlert(title: "Cannot find your location", message: "Please try again")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        callATuberButton.isHidden = true
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("userName", equalTo: (PFUser.current()?.username)!)
        
        query.findObjectsInBackground {
            (objects, error) in
            if objects != nil { // or search for stopupdatinglocation
                self.riderRequestActive = true
                self.callATuberButton.isEnabled = true
                self.callATuberButton.setTitle("Cancel Uber", for: [])
                
            }else{
                
                self.riderRequestActive = false
                self.callATuberButton.isEnabled = true
            }
            self.callATuberButton.isHidden = false
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutSegue" {
            
            manager.stopUpdatingLocation() //stop updatinglocation
            PFUser.logOut()
            
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = manager.location?.coordinate{
        
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            if driverOnTheWay == false {
            
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                
                let region = MKCoordinateRegion(center: userLocation!, span: span)
                
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(self.map.annotations)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation!
                annotation.title = title
                
                self.map.addAnnotation(annotation)
                
            }
            if PFUser.current() != nil {
                
                let query = PFQuery(className: "RiderRequest")
                
                query.whereKey("userName", equalTo: (PFUser.current()?.username)!)
                
                query.findObjectsInBackground {
                    (objects, error) in
                    if let riderRequests = objects {
                        
                        for riderRequest in riderRequests {
                            
                            riderRequest["location"] = PFGeoPoint(latitude: self.userLocation!.latitude, longitude: self.userLocation!.longitude)
                            
                            riderRequest.saveInBackground()
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
        if riderRequestActive == true {
           
            let query = PFQuery(className: "RiderRequest")
            //driverResponded
            let thisUser = PFUser.current()?.username
            
            query.whereKey("userName", equalTo: thisUser!)
            
            query.findObjectsInBackground {
                (objects, error) in
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                        if let driverUserName = riderRequest["driverResponded"] {
                            
                            let newQuery = PFQuery(className: "DriverLocation")
                            
                            newQuery.whereKey("username", equalTo: driverUserName)
            
                            newQuery.findObjectsInBackground {
                                (objectts, error) in
                                if let driverLocations = objectts {
                                    
                                    for tmpDriverLocationObj in driverLocations {
                                        
                                        
                                        if let tmpDriverLocation = tmpDriverLocationObj["location"] as? PFGeoPoint {
                                            
                                            self.driverOnTheWay = true
                                            
                                            let tmpDriverCLLocation = CLLocation(latitude: tmpDriverLocation.latitude, longitude: tmpDriverLocation.longitude)
                                            
                                            let tmpRiderCLLocation = CLLocation(latitude: self.userLocation!.latitude, longitude: self.userLocation!.longitude)
                                            
                                            let distance = tmpRiderCLLocation.distance(from: tmpDriverCLLocation) / 1000
                                            
                                            let roundDistance = round(distance * 100) / 100
                                            
                                            self.callATuberButton.setTitle("Driver is \(roundDistance) away", for: [])
                                            
                                            let latDelta = abs(tmpDriverLocation.latitude - self.userLocation!.latitude) * 2 + 0.005
                                            let lonDelta = abs(tmpDriverLocation.longitude - self.userLocation!.longitude) * 2 + 0.005
                                            
                                            let region = MKCoordinateRegion(center: self.userLocation!, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            
                                            self.map.removeAnnotations(self.map.annotations)
                                            
                                            self.map.setRegion(region, animated: true)
                                            
                                            let userLocationAnno = MKPointAnnotation()
                                            userLocationAnno.coordinate = self.userLocation!
                                            userLocationAnno.title = "Your Location"
                                            
                                            self.map.addAnnotation(userLocationAnno)
                                            
                                            let driveLocationAnno = MKPointAnnotation()
                                            driveLocationAnno.coordinate = CLLocationCoordinate2D(latitude: tmpDriverLocation.latitude, longitude: tmpDriverLocation.longitude)
                                            driveLocationAnno.title = "Driver Location"
                                            
                                            self.map.addAnnotation(driveLocationAnno)
                                        }
                                        
                                    }
                                    
                                }
                            }
                            
                        }
                        
                    }
                    
                }
                if error != nil {
                    print(error!)
                }
                
            }
            
        }
        
    }

}
