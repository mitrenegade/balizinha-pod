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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        heatmapLayer = GMUHeatmapTileLayer()
        heatmapLayer.map = mapView
        
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
