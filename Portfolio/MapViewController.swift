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
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    let annotationViewReuseID = "mapPin"
    
    @IBOutlet weak var mapView: MKMapView!
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        imageCache = appDelegate.imageCache
        imageDownloader = appDelegate.imageDownloader
        
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
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ShowPhotoDetailFromMap") {
            let pointAnnotation = sender as? PointAnnotation
            let detailViewController = segue.destinationViewController as? DetailViewController
            
            if (pointAnnotation != nil && pointAnnotation?.photo != nil && detailViewController != nil) {
                detailViewController!.photo = pointAnnotation!.photo!
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
        if (annotation is MKUserLocation) {
            return nil
        }
        
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationViewReuseID)
        var button: UIButton?
        
        if (pin != nil) {
            button = pin!.leftCalloutAccessoryView as? UIButton
            
            pin!.annotation = annotation
        } else {
            button = UIButton(type: UIButtonType.Custom)
            button!.frame.size.width = 46
            button!.frame.size.height = 46
            
            pin = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationViewReuseID)
            pin!.image = UIImage(named: "Pin Photo")
            pin!.leftCalloutAccessoryView = button
            pin!.canShowCallout = true
        }
        
        if let button = button, pointAnnotation = annotation as? PointAnnotation, photo = pointAnnotation.photo {
            displayThumbnail(button, photo: photo)
        }
        
        return pin
    }
    
    // Display photo detail.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control == view.leftCalloutAccessoryView) { // Left button
            if let annotation = view.annotation as? PointAnnotation {
                return performSegueWithIdentifier("ShowPhotoDetailFromMap", sender: annotation)
            }
        }
    }
    
    // Load and display photo thumbnail.
    // Use cache when possible.
    func displayThumbnail(button: UIButton, photo: PhotoModel) {
        let url = photo.getThumbnailForSize(.PIN)?.url
        if (url == nil) {
            return
        }
        
        // Set thumbnail params
        let request = NSURLRequest(URL: NSURL(string: url!)!)
        let size = CGSize(width: 46.0, height: 46.0)
        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(size: size, radius: 6.0)
        
        // Load & store image.
        imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
            if let image: UIImage = response.result.value {
                button.setImage(image, forState: .Normal)
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
        mapView.setRegion(coordinateRegion, animated: false)
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
