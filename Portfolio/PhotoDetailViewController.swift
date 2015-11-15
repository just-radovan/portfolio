//
//  PhotoDetailViewController.swift
//  just Radovan
//
//  Created by Radovan on 01/11/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import MapKit
import AlamofireImage

class PhotoDetailViewController: UIViewController, MKMapViewDelegate {

    // MARK: Properties - location
    let locationManager: CLLocationManager!
    let dataController = DataController()
    let mapRadius: CLLocationDistance = 150 // Metres?
    let annotationViewReuseID = "mapPin"
    
    // MARK: Properties - photo
    var photo: PhotoModel?
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var ratingLabel: UILabel!
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
        
        if let photo = photo {
            self.title = photo.title
            
            // Title
            if let ratingHigh = photo.ratingHigh {
                ratingLabel.text = String(format: "%.1f", ratingHigh)
            }
            
            // Initialize map
            if let latitude = photo.latitude, longitude = photo.longitude {
                let photoLocation = CLLocation(latitude: latitude, longitude: longitude)
                
                setUpMap(photoLocation)
                addAnnotationToMap(photo.title, latitude: latitude, longitude: longitude)
            }
            
            // Photo
            if let thumbnail = photo.getThumbnailForSize(.FULL) {
                let request = NSURLRequest(URL: NSURL(string: thumbnail.url)!)
                let size = CGSize(width: 600.0, height: 337.0)
                let filter = AspectScaledToFillSizeFilter(size: size)
                
                // Load & store image.
                imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
                    if let image: UIImage = response.result.value {
                        self.photoImageView.image = image
                    }
                }
            }
        }
        
        // Request phones' location
        let locationState = CLLocationManager.authorizationStatus()
        if (locationState == CLAuthorizationStatus.NotDetermined){
            locationManager.requestWhenInUseAuthorization()
        } else {
            mapView.showsUserLocation = true
        }
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
        
        if let button = button {
            displayThumbnail(button)
        }
        
        return pin
    }
    
    // Load and display photo thumbnail.
    // Use cache when possible.
    func displayThumbnail(button: UIButton) {
        if (photo == nil) {
            return
        }
        
        let url = photo!.getThumbnailForSize(.PIN)?.url
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
    
    // Center map to given location.
    func setUpMap(center: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            center.coordinate,
            mapRadius,
            mapRadius
        )
        
        mapView.mapType = MKMapType.Satellite
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // Add annotation to the map
    func addAnnotationToMap(title: String, latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        
        mapView.addAnnotation(annotation)
    }
}
