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

class DetailViewController: UITableViewController, MKMapViewDelegate {
    
    // MARK: Properties - photo
    var photo: PhotoModel?
    
    // MARK: Properties - table cells
    let cells = [
        "DetailPhotoTableViewCell",
        "DetailExifTableViewCell",
        "DetailMapTableViewCell"
    ]
    
    // MARK: Properties - data
    let cameraList = CameraList()
    let lensList = LensList()
    
    // MARK: Properties - image loader
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    var width: CGFloat! = 600.0 // Default width of UIImageView; 16:9.
    var height: CGFloat! = 337.0 // Default height of UIImageView; 16:9.
    
    // MARK: Properties - location
    let locationManager: CLLocationManager!
    let dataController = DataController()
    let mapRadius: CLLocationDistance = 150 // Metres?
    let annotationViewReuseID = "mapPin"
    
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
        }
    }
    
    // MARK: TableView
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.row {
        case 0:
            self.tableView.rowHeight = 337 // Default height, will be changed in prepareCellPhoto()
            cell = prepareCellPhoto(indexPath)
        case 1:
            self.tableView.rowHeight = 184
            cell = prepareCellExif(indexPath)
        default:
            self.tableView.rowHeight = 300
            cell = prepareCellMap(indexPath)
        }
        
        return cell;
    }
    
    // MARK: MapView
    
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
    
    // MARK: Cell preparation
    
    // Prepare cell with photo.
    func prepareCellPhoto(indexPath: NSIndexPath) -> DetailPhotoTableViewCell {
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! DetailPhotoTableViewCell
        
        if let photo = photo {
            // Calculate photo view size.
            if let photoWidth = photo.width, photoHeight = photo.height {
                let ratio = CGFloat(photoWidth) / CGFloat(photoHeight)
                
                height = width / ratio
            }
            
            let viewRatio = width / cell.frame.width
            width = width / viewRatio
            height = height / viewRatio
            
            // Set table cell height.
            self.tableView.rowHeight = height
            
            // Photo.
            if let thumbnail = photo.getThumbnailForSize(.FULL) {
                let request = NSURLRequest(URL: NSURL(string: thumbnail.url)!)
                let size = CGSize(width: width, height: height)
                let filter = AspectScaledToFillSizeFilter(size: size)
                
                // Load & store image.
                imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
                    if let image: UIImage = response.result.value {
                        let imageView = UIImageView(image: image)
                        
                        imageView.frame = CGRect(
                            x: 0.0, y: 0.0,
                            width: self.width, height: self.height
                        )
                        imageView.clipsToBounds = true
                        imageView.sizeToFit()
                        
                        cell.insertSubview(imageView, atIndex: 0)
                    }
                }
            }
        }
        
        return cell
    }
    
    // Prepare cell with EXIF meta data.
    func prepareCellExif(indexPath: NSIndexPath) -> DetailExifTableViewCell {
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! DetailExifTableViewCell
        
        if let photo = photo {
            if let ratingHigh = photo.ratingHigh {
                cell.ratingLabel.text = String(format: "%.1f", ratingHigh)
            }
            if let camera = photo.camera {
                if let cameraName = cameraList.list[camera] {
                    cell.cameraLabel.text = cameraName
                } else {
                    cell.cameraLabel.text = camera
                }
            }
            if let lens = photo.lens {
                if let lensName = lensList.list[lens] {
                    cell.lensLabel.text = lensName
                } else {
                    cell.lensLabel.text = lens
                }
            }
            if let focalLength = photo.focalLength {
                cell.focalLengthLabel.text = focalLength + "mm"
            }
            if let aperture = photo.aperture {
                cell.apertureLabel.text = "f/" + aperture
            }
            if let shutterSpeed = photo.shutterSpeed {
                cell.shutterSpeedLabel.text = shutterSpeed + "s"
            }
            if let sensitivity = photo.iso {
                cell.sensitivityLabel.text = "ISO" + sensitivity
            }
        }
        
        return cell
    }
    
    // Prepare cell with map.
    func prepareCellMap(indexPath: NSIndexPath) -> DetailMapTableViewCell {
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! DetailMapTableViewCell
    
        cell.mapView.delegate = self
        
        if let photo = photo {
            // Initialize map
            if let latitude = photo.latitude, longitude = photo.longitude {
                let photoLocation = CLLocation(latitude: latitude, longitude: longitude)
                
                setUpMap(cell, center: photoLocation)
                addAnnotationToMap(cell, title: photo.title, latitude: latitude, longitude: longitude)
            }
        }
        
        // Request phones' location
        let locationState = CLLocationManager.authorizationStatus()
        if (locationState == CLAuthorizationStatus.NotDetermined){
            locationManager.requestWhenInUseAuthorization()
        } else {
            cell.mapView.showsUserLocation = true
        }
        
        return cell
    }
    
    // MARK: Map functions
    
    // Center map to given location.
    func setUpMap(cell: DetailMapTableViewCell, center: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            center.coordinate,
            mapRadius,
            mapRadius
        )
        
        cell.mapView.mapType = MKMapType.Satellite
        cell.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // Add annotation to the map
    func addAnnotationToMap(cell: DetailMapTableViewCell, title: String, latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        
        cell.mapView.addAnnotation(annotation)
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
}
