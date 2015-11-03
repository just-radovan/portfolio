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
                centerMapOnLocation(CLLocation(latitude: latitude, longitude: longitude))
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
    }
    
    // Center map to given location.
    func centerMapOnLocation(location: CLLocation) {
        let radius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            location.coordinate,
            radius * 2.0,
            radius * 2.0
        )
        mapView.setRegion(coordinateRegion, animated: true)
    }
}
