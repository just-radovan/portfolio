//
//  PhotoTableViewController.swift
//  Portfolio
//
//  Created by Radovan on 29/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import MapKit
import AlamofireImage

class PhotoTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    // MARK: Properties - photos
    let dataController = DataController()
    let thumbnailCacheID = "thumbnail"
    var photos = [PhotoModel]()
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    // MARK: Properties - location
    let locationManager: CLLocationManager!
    var lastKnownLocation: CLLocation?
    // MARK: Properties - stuff
    let dateFormatter = NSDateFormatter()
    
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
        
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPhotos()
        initLocation()
        
        let downloader = PhotoDownloader()
        downloader.downloadAll() { downloadedPhotos in
            print("Photos saved: \(downloadedPhotos)")
            
            if (downloadedPhotos > 0) {
                self.loadPhotos()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailViewController = segue.destinationViewController as! PhotoDetailViewController
        if let selectedCell = sender as? PhotoTableViewCell {
            let indexPath = tableView.indexPathForCell(selectedCell)!
            let selectedPhoto = photos[indexPath.row]
            
            detailViewController.photo = selectedPhoto
        }
    }

    // MARK: TableView
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellId = "PhotoTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! PhotoTableViewCell
        
        let photo = photos[indexPath.row]
        
        // Display photo details.
        cell.titleLabel.text = photo.title

        if let taken = photo.taken {
            cell.takenLabel.text = dateFormatter.stringFromDate(taken)
        } else {
            cell.takenLabel.text = ""
        }
        
        // Distance
        if let lastLocation = lastKnownLocation, latitude = photo.latitude, longitude = photo.longitude {
            let photoLocation = CLLocation(latitude: latitude, longitude: longitude)
            cell.distanceLabel.text = String(
                format: "%0.2f km",
                lastLocation.distanceFromLocation(photoLocation) / 1000.0
            )
        } else {
            cell.distanceLabel.text = nil
        }
        
        // Thumbnail
        if let thumbnail = photo.getThumbnailForSize(.THUMB) {
            displayThumbnail(cell, id: photo.id, url: thumbnail.url)
        }
        
        return cell
    }
    
    // Receive scroll events.
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        // TODO: Allow cells to display thumbnail, cancel request not valid anymore.
    }
    
    // MARK: Photos
    // Load and display photos.
    func loadPhotos() {
        if let photoModels = dataController.getPhotos() {
            photos = photoModels
            tableView.reloadData()
        }
    }
    
    // Load and display photo thumbnail.
    // Use cache when possible.
    func displayThumbnail(cell: PhotoTableViewCell, id: Int64, url: String) {
        // Cancel outdated requests
        if let requestReceipt = cell.requestReceipt {
            imageDownloader.cancelRequestForRequestReceipt(requestReceipt)
            cell.thumbnailView.image = nil
        }
        
        // Set thumbnail params
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let size = CGSize(width: 160.0, height: 90.0)
        let filter = AspectScaledToFillSizeFilter(size: size)
        
        // Load & store image.
        cell.requestReceipt = imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
            if let image: UIImage = response.result.value {
                cell.thumbnailView.image = image
                cell.requestReceipt = nil
            }
        }
    }
    
    // MARK: Location
    // Receive current location from CLLocationManager
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            lastKnownLocation = locations[locations.count - 1]
            tableView.reloadData()
        }
    }
    
    // Get user's location.
    func initLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
}
