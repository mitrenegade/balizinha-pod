//
//  HeatMapViewController.swift
//  Balizinha_Example
//
//  Created by Bobby Ren on 5/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import GoogleMaps
import GoogleUtilities
import Balizinha
import RenderCloud

class HeatMapViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    private var heatmapLayer: GMUHeatmapTileLayer!
    var locations = [CLLocationCoordinate2D]()
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var zoomLevel: Float = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        heatmapLayer = GMUHeatmapTileLayer()
        heatmapLayer.map = mapView
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        load()
    }
    
    func load() {
        locations = []
        let playerRef = firRef.child("players")
        playerRef.observe(.value) {[weak self] (snapshot) in
            guard snapshot.exists() else { return }
            if let allObjects =  snapshot.allChildren {
                for playerDict in allObjects {
                    let player = Player(snapshot: playerDict)
                    if let lat = player.lat, let lon = player.lon {
                        self?.locations.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                }
            }
            self?.addHeatmap()
        }
    }

    func addHeatmap()  {
        var list = [GMUWeightedLatLng]()
        for location in locations {
            let coords = GMUWeightedLatLng(coordinate: location, intensity: 1.0)
            list.append(coords)
        }
        // Add the latlngs to the heatmap layer.
        heatmapLayer.weightedData = list
    }
}

extension HeatMapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
