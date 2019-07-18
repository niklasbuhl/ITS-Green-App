//
//  ViewController.swift
//  sync-app
//
//  Created by Niklas Buhl on 13/05/2019.
//  Copyright © 2019 Niklas Buhl. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // ------------------------------------------------------------------------
    // Variables
    // ------------------------------------------------------------------------
    
    // Location Manager
    var locationManager: CLLocationManager = CLLocationManager()
    
    // Send Once Control
    var sendLocationAndSpeedReady = false
    var sendCourseReady = false
    
    // data
    var course : CLLocationDirection = 0.0
    var latitude : Double = 0.0
    var longitude : Double = 0.0
    var speed: CLLocationSpeed = 0.0
    
    // Sending Updates
    var timeSinceLastUpdate = 0
    var updateTimer = 1000 // 2 seconds
    var sendOnce = false
    
    // Url
//    let hostname: String = "https://ekymjshb.p51.rt3.io"
//    let hostname: String = "https://172.20.10.4"
    let hostname: String = "http://172.20.10.4"
    
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var lonLabel: UILabel!
    @IBOutlet weak var kmhLabel: UILabel!
    @IBOutlet weak var corLabel: UILabel!
    
    // ------------------------------------------------------------------------
    // Everytime the 'Send Location' button is pressed and released
    // ------------------------------------------------------------------------
    
    @IBAction func sendLocationAction(_ sender: Any) {
        print("Send Location Once!")
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        sendOnce = true
    }
    
    @IBOutlet weak var continouslyTrack: UISwitch!
    
    // ------------------------------------------------------------------------
    // Everytime the switch is toggled
    // ------------------------------------------------------------------------
    
    @IBAction func toggleContinousTrackingAction(_ sender: Any) {
        print("Continously Tracking Toggle Changed!")
        
        if continouslyTrack.isOn == true {
            print("Continously Tracking ON!")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        } else {
            print("Continously Tracking OFF!")
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
        }
    
    }
    
    // ------------------------------------------------------------------------
    // Heading / Course
    // ------------------------------------------------------------------------
    // This function is called everytime the heading is updated.
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        
        // Get the heading data
        course = heading.magneticHeading
        
        // Convert the heading to a string
        let corValue:String = String(format:"%.0f", course)
        
        // Update the label
        corLabel.text = corValue + "°"
        
        if continouslyTrack.isOn == false {
            locationManager.stopUpdatingHeading()
        }
        
        sendCourseReady = true
        
        checkData()
        
    
    }
    
    // ------------------------------------------------------------------------
    // Location
    // ------------------------------------------------------------------------
    // This function is called everytime the location is updated.
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        // Get the location data
        let location : CLLocationCoordinate2D = manager.location!.coordinate

        latitude = location.latitude
        longitude = location.longitude
        
        // Convert the latitude and longitude to strings
        let latValue:String = String(format:"%.6f", latitude)
        let lonValue:String = String(format:"%.6f", longitude)
        
        // Set the labels in the UI
        latLabel.text = latValue + "°"
        lonLabel.text = lonValue + "°"
        
        // Get the speed data
        speed = manager.location!.speed
        
        // Convert speed to string
        let speedValue:String = String(format:"%.2f", speed)
        
        kmhLabel.text = speedValue + " ms"
        
        if continouslyTrack.isOn == false {
            locationManager.stopUpdatingLocation()
        }
        
        sendLocationAndSpeedReady = true
        
        checkData()
        
    }

    // ------------------------------------------------------------------------
    // Check is data is there
    // ------------------------------------------------------------------------
    // Check if both location(and speed) and course data is ready, and then if the timing is good.
    
    func checkData() {
        
        print("Checking Data...")
        
        if sendLocationAndSpeedReady && sendCourseReady {
            
            let now = Int (Date().timeIntervalSince1970 * 1000)
            
            let difference = now - timeSinceLastUpdate
            
            if (difference > updateTimer || sendOnce) {
                
                print("Updating: \(now) EPOCH")
                print("Difference: \(Float(difference)/2000)s")
                print("Course: \(course)")
                print("Latitude: \(latitude)")
                print("Longitude: \(longitude)")
                print("Speed: \(speed)ms")
                
                sendLocationAndSpeedReady = false
                sendCourseReady = false
                
                if sendOnce { sendOnce = false }
                
                timeSinceLastUpdate = now
                
                sendData()
                
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Send Data
    // ------------------------------------------------------------------------
    // Send the data with the JSON http GET request
    
    func sendData() {
        
        print("Sending data...")
        
        // Prepare JSON
        let json: [String: Any] = [
            "time": "\(timeSinceLastUpdate)",
            "latitude": "\(latitude)",
            "longitude": "\(longitude)",
            "speed": "\(speed)",
            "course": "\(course)"
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        httpGETRequestWithJSON(parameter: "/api/session/setbicycle/", jsondata: jsonData!)
        
    }
    
    // ------------------------------------------------------------------------
    // HTTP GET Request
    // ------------------------------------------------------------------------
    
    func httpGetRequest(parameter: String) {
        
        print("Sending Stand Alone Function");
        
        // Url
        let path: String = parameter
        
        let url = hostname + path
        
        print("URL: \(url)")
        
        // Request
        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        
        // Set request method
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Checking for networking errors
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            // If the response code is the 200s, then we're all good
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // Response data
            let responseString = String(data: data, encoding: .utf8)
            let noResponse = "No response"
            print("responseString = \(responseString ?? noResponse)")
        }
        
        task.resume()
        
    }
    
    // ------------------------------------------------------------------------
    // HTTP GET with JSON body
    // ------------------------------------------------------------------------
    
    func httpGETRequestWithJSON(parameter: String, jsondata: Data) {
        
        print("Sending Stand Alone Function");
        
        let path: String = parameter
        
        let url = hostname + path
        
        print("URL: \(url)")
        print(jsondata)
        
        // Request
        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        
        // Set request method
        request.httpMethod = "POST"
        request.httpBody = jsondata
//        request.setValue("Content-Type", forHTTPHeaderField: "application/json")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("HTTP GET request setup...")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Checking for networking errors
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            // If the response code is the 200s, then we're all good
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            // Response json
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
            
            // Response data
            let responseString = String(data: data, encoding: .utf8)
            let noResponse = "No response"
            print("responseString = \(responseString ?? noResponse)")
        }
        
        task.resume()
        
        print("Request done!")
        
    }
    
    // ------------------------------------------------------------------------
    // Main function
    // ------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set all values
        latLabel.text = "0.0"
        lonLabel.text = "0.0"
        kmhLabel.text = "0.0"
        corLabel.text = "0.0"
        
        // Hello World
        print("Hello World! Version 2")
        
        // Location
        locationManager.delegate = self
        
        // Set the accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Make sure the iPhone user want the location to be shared
        locationManager.requestAlwaysAuthorization()
    
    }
}

