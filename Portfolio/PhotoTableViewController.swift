//
//  PhotoTableViewController.swift
//  Portfolio
//
//  Created by Radovan on 29/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import AlamofireImage

class PhotoTableViewController: UITableViewController {
    
    let dateFormatter = NSDateFormatter()
    let imageDownloader = ImageDownloader(
        configuration: ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: .FIFO,
        maximumActiveDownloads: 4,
        imageCache: AutoPurgingImageCache()
    )
    let imageCache = AutoPurgingImageCache(
        memoryCapacity: 100 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )
    let thumbnailCacheID = "thumbnail"
    let dataController = DataController()
    var photos = [PhotoModel]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        dateFormatter.dateFormat = "dd.MM.yyyy"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
  
        loadPhotos()
        
        let downloader = PhotoDownloader()
        downloader.downloadAll() { downloadedPhotos in
            print("Photos downloaded: \(downloadedPhotos)")
            
            if (downloadedPhotos > 0) {
                self.loadPhotos()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

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
        cell.descLabel.text = photo.desc

        if let taken = photo.taken {
            cell.takenLabel.text = dateFormatter.stringFromDate(taken)
        } else {
            cell.takenLabel.text = ""
        }
        
        if let thumbnails = photo.thumbnails {
            if thumbnails.count > 0 {
                displayThumbnail(cell, id: photo.id, url: thumbnails[0].url)
            }
        }
        
        return cell
    }
    
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
        let request = NSURLRequest(URL: NSURL(string: url)!)
        
        if let image = imageCache.imageForRequest(request, withAdditionalIdentifier: thumbnailCacheID) {
            // Use image from cache.
            cell.thumbnailView.image = image
        } else {
            // Load & store image.
            let size = CGSize(width: 160.0, height: 90.0)
            let filter = AspectScaledToFillSizeFilter(size: size)
            
            imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
                if let image = response.result.value {
                    self.imageCache.addImage(
                        image,
                        forRequest: request,
                        withAdditionalIdentifier: self.thumbnailCacheID
                    )
                    
                    cell.thumbnailView.image = image
                }
            }
        }
    }
}
