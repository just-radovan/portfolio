//
//  MapViewController.swift
//  just Radovan
//
//  Created by Radovan on 11.11.15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    let locationManager: CLLocationManager!
    let mapRadius: CLLocationDistance = 2000 // Metres?
    var mapCentered = false
    
    @IBOutlet weak var mapView: MKMapView!
    
    required init?(coder aDecoder: NSCoder) {
        locationManager = CLLocationManager()
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Request phones' location
        let locationState = CLLocationManager.authorizationStatus()
        if (locationState == CLAuthorizationStatus.NotDetermined){
            locationManager.requestWhenInUseAuthorization()
        } else {
            mapView.showsUserLocation = true
        }
    }
    
    // Center map to user's location. Only once.
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if (mapCentered || userLocation.location == nil) {
            return
        }
        
        setUpMap(userLocation.location!)
        mapCentered = true
    }
    
    // Center and zoom the map.
    func setUpMap(center: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            center.coordinate,
            mapRadius,
            mapRadius
        )
        
        mapView.mapType = MKMapType.Standard
        mapView.setRegion(coordinateRegion, animated: true)
    }
}
