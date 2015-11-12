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

class PhotoDetailViewController: UIViewController {

    let locationManager: CLLocationManager!
    let dataController = DataController()
    let mapRadius: CLLocationDistance = 150 // Metres?
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
    
    // Add annotation to map
    func addAnnotationToMap(title: String, latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        
        mapView.addAnnotation(annotation)
    }
}
