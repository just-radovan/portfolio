//
//  MapViewController.swift
//  just Radovan
//
//  Created by Radovan on 11.11.15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import MapKit
import AlamofireImage

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Properties - location
    let locationManager: CLLocationManager!
    let mapRadius: CLLocationDistance = 2000 // Metres?
    var mapCentered = false
    
    // MARK: Properties - photos
    let dataController = DataController()
    var photos = [PhotoModel]()
    let annotationViewReuseID = "mapPin"
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    
    @IBOutlet weak var mapView: MKMapView!
    
    required init?(coder aDecoder: NSCoder) {
        imageCache = AutoPurgingImageCache(
            memoryCapacity: 100 * 1024 * 1024,
            preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
        )
        imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .LIFO,
            maximumActiveDownloads: 4,
            imageCache: imageCache
        )
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
    
    // Handle adding annotation view to the map.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (!(annotation is PointAnnotation)) {
            return nil
        }
        
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationViewReuseID) as? PinAnnotationView
        if (pin == nil) {
            pin = PinAnnotationView(annotation: annotation, reuseIdentifier: annotationViewReuseID)
            pin!.canShowCallout = true
        } else {
            pin!.annotation = annotation
        }
        
        let point = annotation as! PointAnnotation
        if let photo = point.photo, thumbnail = photo.getThumbnailForSize(.PIN) {
            displayThumbnail(pin!, id: photo.id, url: thumbnail.url)
        }
        
        return pin
    }
    
    // Display thumbnail on pin annotation view.
    func displayThumbnail(pin: PinAnnotationView, id: Int64, url: String) {
        // Cancel outdated requests
        if let requestReceipt = pin.requestReceipt {
            imageDownloader.cancelRequestForRequestReceipt(requestReceipt)
            pin.image = nil
        }
        
        // Set thumbnail params
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let size = CGSize(width: 32.0, height: 32.0)
        let filter = AspectScaledToFillSizeFilter(size: size)
        
        // Load & store image.
        pin.requestReceipt = imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
            if let image: UIImage = response.result.value {
                pin.image = image
                pin.requestReceipt = nil
            }
        }
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
                let annotation = PointAnnotation()
                annotation.photo = photo
                annotation.coordinate = location
                annotation.title = photo.title
                
                mapView.addAnnotation(annotation)
            }
        }
    }
}
