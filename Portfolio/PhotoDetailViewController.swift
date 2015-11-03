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
                zoomMap(latitude, longitude: longitude)
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
    func zoomMap(latitude: Double, longitude: Double) {
        let center: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        let radius: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            center.coordinate,
            radius * 2.0,
            radius * 2.0
        )
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
