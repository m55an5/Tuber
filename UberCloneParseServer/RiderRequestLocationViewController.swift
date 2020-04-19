//
//  RiderRequestLocationViewController.swift
//  UberCloneParseServer
//
//  Created by Manjot S Sandhu on 19/4/20.
//  Copyright © 2020 Manjot S Sandhu. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RiderRequestLocationViewController: UIViewController, MKMapViewDelegate {
    
    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var requestUserName = ""
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var acceptRequest: UIButton!
    
    @IBAction func acceptRequestPressed(_ sender: Any) {
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("userName", equalTo: requestUserName)
        
        query.findObjectsInBackground {
            (objects, error) in
            if let riderRequests = objects {
                
                for riderRequest in riderRequests {
                    
                    riderRequest["driverResponded"] = PFUser.current()?.username
                    
                    riderRequest.saveInBackground()
                    
                    // reverse geo coding to take to apple maps
                    
                    let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                    
                    CLGeocoder().reverseGeocodeLocation(requestCLLocation) {
                        (placemarks, error) in
                        if let placemarks = placemarks {
                            
                            if placemarks.count > 0 {
                                
                                let mkPlacemark = MKPlacemark(placemark: placemarks[0])
                                
                                let mapItem = MKMapItem(placemark: mkPlacemark)
                                
                                mapItem.name = self.requestUserName
                                
                                let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                mapItem.openInMaps(launchOptions: launchOptions)
                            }
                            
                        }
                    }
                    
                    
                }
                
            }
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        
        self.map.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestUserName
        self.map.addAnnotation(annotation)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
