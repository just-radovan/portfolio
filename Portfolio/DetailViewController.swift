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
    
    // MARK: Properties - layout
    let paddingBottom: CGFloat = 91.0
    
    // MARK: Properties - data
    let cameraList = CameraList()
    let lensList = LensList()
    
    // MARK: Properties - image loader
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    var photoPlaceholderView: UIImageView?
    var photoView: UIImageView?
    var width: CGFloat! = 600.0 // Default width of UIImageView; 16:9.
    var height: CGFloat! = 337.0 // Default height of UIImageView; 16:9.
    
    // MARK: Properties - location
    let locationManager: CLLocationManager!
    let dataController = DataController()
    let mapRadius: CLLocationDistance = 150 // Metres?
    let annotationViewReuseID = "mapPin"
    var lastKnownUserLocation: MKUserLocation?
    var userChangedMap: Bool = false

    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        imageCache = appDelegate.imageCache
        imageDownloader = appDelegate.imageDownloader
        
        locationManager = CLLocationManager()
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photo {
            self.title = photo.title
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if let navigationController = self.parentViewController as? PortfolioNavigationController {
            navigationController.setBlackNavigationBar()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let navigationController = self.parentViewController as? PortfolioNavigationController {
            navigationController.setWhiteNavigationBar()
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
        let exifHeight: CGFloat = 156.0
        
        switch indexPath.row {
        case 0:
            // Display only photo and rating on screen. Scroll for more.
            if let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height {
                self.tableView.rowHeight = self.tableView.frame.height - navigationBarHeight - paddingBottom
            } else {
                self.tableView.rowHeight = self.tableView.frame.height - paddingBottom
            }
            
            return prepareCellPhoto(indexPath)
        case 1:
            self.tableView.rowHeight = exifHeight
            
            return prepareCellExif(indexPath)
        default:
            // Fill the screen with EXIF data and the map.
            if let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height {
                self.tableView.rowHeight = self.tableView.frame.height - navigationBarHeight - exifHeight - 8
            } else {
                self.tableView.rowHeight = self.tableView.frame.height - exifHeight - 8
            }
            
            return prepareCellMap(indexPath)
        }
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
    
    // Handle new user's location.
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        lastKnownUserLocation = userLocation
        
        adaptMapViewport(mapView: mapView)
    }
    
    // Handle map movement.
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        userChangedMap = mapViewRegionDidChangeFromUserInteraction(mapView: mapView)
    }
    
    // MARK: Cell preparation
    
    // Prepare cell with photo.
    func prepareCellPhoto(indexPath: NSIndexPath) -> DetailPhotoTableViewCell {
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! DetailPhotoTableViewCell
        
        // Remove old photo, if exists.
        if (photoView != nil) {
            photoView!.removeFromSuperview()
        }
        
        if let photo = photo {
            // Calculate photo view size.
            if let photoWidth = photo.width, photoHeight = photo.height {
                let ratio = CGFloat(photoWidth) / CGFloat(photoHeight)
                
                height = width / ratio
            }
            
            // Scale photo to fit in cell.
            let viewWidthRatio = width / cell.frame.width
            let viewHeightRatio = height / cell.frame.height
            
            if (viewWidthRatio > viewHeightRatio) {
                width = width / viewWidthRatio
                height = height / viewWidthRatio
            } else {
                width = width / viewHeightRatio
                height = height / viewHeightRatio
            }
            
            // Display placeholder.
            displayPhotoPlaceholder(cell)
            
            // Photo.
            if let thumbnail = photo.getThumbnailForSize(.FULL) {
                let request = NSURLRequest(URL: NSURL(string: thumbnail.url)!)
                let size = CGSize(width: width, height: height)
                let filter = AspectScaledToFillSizeFilter(size: size)
                
                // Load & store image.
                imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
                    if let image: UIImage = response.result.value {
                        let imageView = UIImageView(image: image)
                        
                        var x: CGFloat = 0.0
                        if (cell.frame.width > image.size.width) {
                            x = (cell.frame.width - image.size.width) / 2.0
                        }
                        
                        var y: CGFloat = 0.0
                        if (cell.frame.height > image.size.height) {
                            y = (cell.frame.height - image.size.height) / 2.0
                        }
                        
                        imageView.frame = CGRect(
                            x: x, y: y,
                            width: self.width, height: self.height
                        )
                        imageView.clipsToBounds = true
                        imageView.sizeToFit()
                        
                        self.photoPlaceholderView?.removeFromSuperview()
                        cell.addSubview(imageView)
                        
                        self.photoView = imageView
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
            // Rating.
            if let ratingHigh = photo.ratingHigh {
                cell.ratingLabel.text = String(format: "%.1f", ratingHigh)
            }
            
            // Camera & lens.
            var cameraDetail: NSMutableAttributedString?
            
            if let camera = photo.camera {
                if let cameraName = cameraList.list[camera] {
                    cameraDetail = appendText(
                        cameraDetail,
                        add: cameraName,
                        separator: nil,
                        styleSeparator: true
                    )
                } else {
                    cameraDetail = appendText(
                        cameraDetail,
                        add: camera,
                        separator: nil,
                        styleSeparator: true
                    )
                }
            }
            
            if let lens = photo.lens {
                if let lensName = lensList.list[lens] {
                    cameraDetail = appendText(
                        cameraDetail,
                        add: lensName,
                        separator: " & ",
                        styleSeparator: true
                    )
                } else {
                    cameraDetail = appendText(
                        cameraDetail,
                        add: lens,
                        separator: " & ",
                        styleSeparator: true
                    )
                }
            }
            cell.cameraLabel.attributedText = cameraDetail
            
            // EXIF data.
            var photoDetail: NSMutableAttributedString?
            
            if let focalLength = photo.focalLength {
                photoDetail = appendText(
                    photoDetail,
                    add: focalLength + "mm",
                    separator: " // ",
                    styleSeparator: true
                )
            }
            if let aperture = photo.aperture {
                photoDetail = appendText(
                    photoDetail,
                    add: "ƒ/" + aperture,
                    separator: " // ",
                    styleSeparator: true
                )
            }
            if let shutterSpeed = photo.shutterSpeed {
                photoDetail = appendText(
                    photoDetail,
                    add: shutterSpeed + "s",
                    separator: " // ",
                    styleSeparator: true
                )
            }
            if let sensitivity = photo.iso {
                photoDetail = appendText(
                    photoDetail,
                    add: "ISO" + sensitivity,
                    separator: " // ",
                    styleSeparator: true
                )
            }
            
            cell.photoLabel.attributedText = photoDetail
        }
        
        return cell
    }
    
    // Prepare cell with map.
    func prepareCellMap(indexPath: NSIndexPath) -> DetailMapTableViewCell {
        let cellId = cells[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! DetailMapTableViewCell
    
        cell.mapView.delegate = self
        userChangedMap = false
        
        if let photo = photo {
            // Initialize map
            if let latitude = photo.latitude, longitude = photo.longitude {
                let photoLocation = CLLocation(latitude: latitude, longitude: longitude)
                
                if (lastKnownUserLocation != nil) {
                    adaptMapViewport(mapView: cell.mapView)
                } else {
                    setUpMap(cell, center: photoLocation)
                }
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
    
    // Check if user moved the map.
    private func mapViewRegionDidChangeFromUserInteraction(mapView mapView: MKMapView) -> Bool {
        let view = mapView.subviews[0]
        
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Center map to given location.
    private func setUpMap(cell: DetailMapTableViewCell, center: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(
            center.coordinate,
            mapRadius,
            mapRadius
        )
        
        cell.mapView.mapType = MKMapType.Satellite
        cell.mapView.setRegion(coordinateRegion, animated: false)
    }
    
    
    // Adapt viewport to make visible photo location and user location.
    private func adaptMapViewport(mapView mapView: MKMapView) {
        if (userChangedMap) {
            return // User changed viewport.
        }
        if (lastKnownUserLocation == nil) {
            return // We don't have user's location.
        }
        if (photo == nil || photo?.latitude == nil || photo?.longitude == nil) {
            return // We don't have location of the photo.
        }
        
        // Center.
        let centerLatitude = (lastKnownUserLocation!.coordinate.latitude + photo!.latitude!) / 2.0
        let centerLongitude = (lastKnownUserLocation!.coordinate.longitude + photo!.longitude!) / 2.0
        let center = CLLocationCoordinate2DMake(centerLatitude, centerLongitude)
        
        // Span.
        var latitudeDelta: Double
        if (lastKnownUserLocation!.coordinate.latitude < photo!.latitude!) {
            latitudeDelta = photo!.latitude! - lastKnownUserLocation!.coordinate.latitude
        } else {
            latitudeDelta = lastKnownUserLocation!.coordinate.latitude - photo!.latitude!
        }
        
        var longitudeDelta: Double
        if (lastKnownUserLocation!.coordinate.longitude < photo!.longitude!) {
            longitudeDelta = photo!.longitude! - lastKnownUserLocation!.coordinate.longitude
        } else {
            longitudeDelta = lastKnownUserLocation!.coordinate.longitude - photo!.longitude!
        }
        
        let span = MKCoordinateSpanMake(
            latitudeDelta * 1.2,
            longitudeDelta * 1.2
        )
        
        // Zomm map to computed viewport.
        let viewport = MKCoordinateRegionMake(center, span);
        
        mapView.setRegion(viewport, animated: true)
    }
    
    // Add annotation to the map
    private func addAnnotationToMap(cell: DetailMapTableViewCell, title: String, latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = title
        
        cell.mapView.addAnnotation(annotation)
    }
    
    // Load and display photo thumbnail.
    // Use cache when possible.
    private func displayThumbnail(button: UIButton) {
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
    
    // MARK: Common methods
    
    // Display photo placeholder.
    func displayPhotoPlaceholder(cell: DetailPhotoTableViewCell) {
        if let image = UIImage(named: "Photo Placeholder") {
            let placeholderView = UIImageView(image: image)
            
            var x: CGFloat = 0.0
            if (cell.frame.width > image.size.width) {
                x = (cell.frame.width - image.size.width) / 2.0
            }
            
            var y: CGFloat = 0.0
            if (cell.frame.height > image.size.height) {
                y = (cell.frame.height - image.size.height) / 2.0
            }
            
            placeholderView.frame = CGRect(
                x: x, y: y,
                width: self.width, height: self.height
            )
            placeholderView.clipsToBounds = true
            placeholderView.sizeToFit()
            
            cell.addSubview(placeholderView)
            
            photoPlaceholderView = placeholderView
        }
    }
    
    // Append strings to attributed string.
    func appendText(text: NSMutableAttributedString?, add: String, separator: String?, styleSeparator: Bool) -> NSMutableAttributedString {
        if (text != nil) {
            if (separator != nil) {
                let range = NSRange(location: text!.length, length: separator!.characters.count)
                text!.appendAttributedString(NSAttributedString(string: separator! + add))
                text!.addAttribute(
                    NSForegroundColorAttributeName,
                    value: UIColor.darkGrayColor(),
                    range: range
                )
                
                return text!
            } else {
                text!.appendAttributedString(NSAttributedString(string: add))
                
                return text!
            }
        } else {
            return NSMutableAttributedString(string: add)
        }
    }
}
