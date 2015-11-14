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

    // MARK: Location
    let locationManager: CLLocationManager!
    let mapRadius: CLLocationDistance = 2000 // Metres?
    var mapCentered = false
    
    // MARK: Properties - photos
    let dataController = DataController()
    var photos = [PhotoModel]()
    
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
        
        // Photos
        loadPhotos()
        
        let downloader = PhotoDownloader()
        downloader.refresh() { downloadedPhotos in
            if (downloadedPhotos > 0) {
                self.loadPhotos()
            }
        }
    }
    
    // MARK: Map
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
    
    // MARK: Photos
    // Load and display photos.
    func loadPhotos() {
        if let photoModels = dataController.getPhotos() {
            photos = photoModels
            addAnnotationsToMap()
        }
    }
    
    // Add annotations to the map.
    func addAnnotationsToMap() {
        for photo in photos {
            if let latitude = photo.latitude, longitude = photo.longitude {
                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = photo.title
                
                mapView.addAnnotation(annotation)
            }
        }
    }
}
