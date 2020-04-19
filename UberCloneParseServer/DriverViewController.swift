//
//  DriverViewController.swift
//  UberCloneParseServer
//
//  Created by Manjot S Sandhu on 19/4/20.
//  Copyright © 2020 Manjot S Sandhu. All rights reserved.
//

import UIKit
import Parse

class DriverViewController: UITableViewController, CLLocationManagerDelegate {
    
    var manager = CLLocationManager()
    
    var requestUserNames = [String]()
    
    var driverLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var requestLocations = [CLLocationCoordinate2D]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    // MARK: = Getting Driver Location
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location?.coordinate {
            
            driverLocation = location
            
            
            let driverLocationUpdtQuery = PFQuery(className: "DriverLocation")
            
            driverLocationUpdtQuery.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            driverLocationUpdtQuery.findObjectsInBackground {
                (objects, error) in
                
                if let driverLocations = objects {
                    
                    if driverLocations.count > 0 {
                    
                        for tmpDriverLocation in driverLocations {
                            
                            tmpDriverLocation["location"] = PFGeoPoint(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
                            
                            tmpDriverLocation.saveInBackground()
                            
                        }
                    }else{
                        
                        let tmpDriverLocation = PFObject(className: "DriverLocation")
                        tmpDriverLocation["username"] = PFUser.current()?.username
                        tmpDriverLocation["location"] = PFGeoPoint(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
                        tmpDriverLocation.saveInBackground()
                        
                    }
                    
                }
            }
            
            
            
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: location.latitude, longitude: location.longitude))
            
            query.limit = 10
            
            query.findObjectsInBackground {
                (objects, error) in
                if let riderRequests = objects {
                    
                    self.requestUserNames.removeAll()
                    self.requestLocations.removeAll()
                    
                    for riderRequest in riderRequests {
                        
                        if let username = riderRequest["userName"] as? String {
                            
                            if riderRequest["driverResponded"] == nil {
                         
                                self.requestUserNames.append(username)
                                let requestUserLocation = riderRequest["location"] as! PFGeoPoint
                                
                                self.requestLocations.append(CLLocationCoordinate2D(latitude: requestUserLocation.latitude, longitude: requestUserLocation.longitude))
                                
                            }
                        }
                        
                    }
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestUserNames.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        
        let riderCLLocation = CLLocation(latitude: requestLocations[indexPath.row].latitude, longitude: requestLocations[indexPath.row].longitude)
        
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        
        let roundDistance = round(distance * 100) / 100
        
        cell.textLabel?.text = requestUserNames[indexPath.row] + " - \(roundDistance) km away"

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driverLogoutSegue" {
            manager.stopUpdatingLocation()
            PFUser.logOut()
            self.navigationController?.navigationBar.isHidden = true
        }
        else if segue.identifier == "showRiderLocationViewCtrl" {
            
            if let destination = segue.destination as? RiderRequestLocationViewController {
                if let row = tableView.indexPathForSelectedRow?.row {
                    destination.requestLocation = requestLocations[row]
                    destination.requestUserName = requestUserNames[row]
                }
            }
        
        }
    }

}
