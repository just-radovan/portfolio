//
//  PhotoCollectionViewController.swift
//  just Radovan
//
//  Created by Radovan on 02/12/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import CoreData
import AlamofireImage

class PhotoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate {

    // MARK: Properties - cells
    let minimumSpacing: CGFloat = 4.0
    let defaultCellWidth: CGFloat = 160.0
    let defaultCellHeight: CGFloat = 160.0
    
    // MARK: Properties - photos
    let dataController: DataController
    let thumbnailCacheID = "thumbnail"
	var collectionSort = PhotoModel.Sort.taken
    var photos = [PhotoModel]()
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    
    // MARK: Properties - stuff
    let dateFormatter = NSDateFormatter()
	
	// MARK: Initialization.
	
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dataController = appDelegate.dataController
        imageCache = appDelegate.imageCache
        imageDownloader = appDelegate.imageDownloader
        
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = minimumSpacing
		layout.sectionInset = UIEdgeInsets(
			top: minimumSpacing,
			left: minimumSpacing,
			bottom: minimumSpacing,
			right: minimumSpacing
		)
        self.collectionView?.collectionViewLayout = layout
        
        if (UIApplication.sharedApplication().keyWindow?.traitCollection.forceTouchCapability == UIForceTouchCapability.Available) {
            self.registerForPreviewingWithDelegate(self, sourceView: self.view)
        }
		
		loadPhotos()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "onPhotosUpdate:", name: "photosUpdateNotification", object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailViewController = segue.destinationViewController as! DetailViewController
        if let collectionView = collectionView, selectedCell = sender as? PhotoCollectionViewCell {
            let indexPath = collectionView.indexPathForCell(selectedCell)!
            let selectedPhoto = photos[indexPath.row]
            
            detailViewController.photo = selectedPhoto
            detailViewController.peek = (segue.identifier == "PeekPhotoDetailFromCollection")
        }
    }
    
    // MARK: Peek & pop
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let indexPath = self.collectionView?.indexPathForItemAtPoint(self.view.convertPoint(location, toView: self.collectionView))
        if (indexPath == nil) {
            return nil
        }
        
        if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as? DetailViewController {
            let selectedPhoto = photos[indexPath!.row]
            
            controller.photo = selectedPhoto
            controller.peek = true
            
            return controller
        }
        
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        if let controller = viewControllerToCommit as? DetailViewController {
            controller.peek = false
            
            self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        }
    }
    
    // MARK: CollectionView

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    // Get cell for given context.
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellId = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = getPhotoAtIndex(indexPath: indexPath)
        
        // Set cell-photo relation.
        if (cell.photoId == photo.id) {
            return cell // Displaying the same cell, no need to refresh it.
        }
        
        cell.photoId = photo.id
        
        // Display photo details.
        cell.titleLabel.text = photo.title
        
        // Thumbnail
        if let thumbnail = photo.getThumbnailForSize(.THUMB) {
            displayThumbnail(cell, photo: photo, url: thumbnail.url)
        }
		
		cell.layer.cornerRadius = 5.0
        
        return cell
    }
    
    // Calculate size of the cell at given index.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // Get photo to be displayed in the cell.
        let photo = getPhotoAtIndex(indexPath: indexPath)
        if (self.collectionView == nil || photo.width == nil || photo.height == nil) {
            return CGSize(width: defaultCellWidth, height: defaultCellHeight) // Default size.
        }
        
        var thisWidth: CGFloat = CGFloat(photo.width!)
        var thisHeight: CGFloat = CGFloat(photo.height!)
        
        // Get pair photo. Photo in the same row; two photos per row.
        var pairPhoto: PhotoModel?
        if (indexPath.row % 2 == 0) {
            if (indexPath.row < photos.count - 1) {
                pairPhoto = getPhotoAtIndex(index: indexPath.row + 1) // Right photo.
            }
        } else {
            if (indexPath.row > 0) {
                pairPhoto = getPhotoAtIndex(index: indexPath.row - 1) // Left photo.
            }
        }
        
        var pairWidth: CGFloat = defaultCellWidth
        var pairHeight: CGFloat = defaultCellHeight
        if (pairPhoto?.width != nil || pairPhoto?.height != nil) {
            pairWidth = CGFloat(pairPhoto!.width!)
            pairHeight = CGFloat(pairPhoto!.height!)
        }
        
        // Get the photo dimensions.
        let thisAspectRatio = thisWidth / thisHeight
        
        if (thisHeight > pairHeight) {
            let scaleRatio = thisHeight / pairHeight
            thisWidth = thisWidth / scaleRatio
            thisHeight = thisHeight / scaleRatio
        } else {
            let scaleRatio = pairHeight / thisHeight
            pairWidth = pairWidth / scaleRatio
            pairHeight = pairHeight / scaleRatio
        }
        
        let collectionWidth = self.collectionView!.frame.width - (minimumSpacing * 3.0)
        let photosRatio = (thisWidth + pairWidth) / thisWidth
        
        let width = floor(collectionWidth / photosRatio)
        let height = round(width / thisAspectRatio)
        
        // Create configuration.
        return CGSize(width: width, height: height)
    }
    
    // MARK: Photos
    
    // Load and display photos.
    private func loadPhotos() {
		if let photoModels = dataController.getPhotos(sort: collectionSort) {
            photos = photoModels
            
            if let view = collectionView {
                view.reloadData()
            }
            
            print("Photos loaded; \(photos.count)")
        } else {
            print("Missing photos!")
        }
    }
    
    // Load and display photo thumbnail.
    // Use cache when possible.
    private func displayThumbnail(cell: PhotoCollectionViewCell, photo: PhotoModel, url: String) {
        // Remove old image.
        cell.photoView?.removeFromSuperview()
        
        // Cancel outdated requests.
        if let requestReceipt = cell.requestReceipt {
            imageDownloader.cancelRequestForRequestReceipt(requestReceipt)
        }
        
        // Calculate thumbnail size.
        var height: CGFloat = 160.0
        var width: CGFloat = 90.0
        
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
        
        // Set thumbnail params.
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let size = CGSize(width: width, height: height)
        let filter = AspectScaledToFillSizeFilter(size: size)
        
        // Load & store image.
        cell.requestReceipt = imageDownloader.downloadImage(URLRequest: request, filter: filter) { response in
            if let image: UIImage = response.result.value {
                let imageView = UIImageView(image: image)
                
                // Fit the image into cell.
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
                    width: image.size.width, height: image.size.height
                )
                imageView.clipsToBounds = true
                imageView.sizeToFit()
                
                // Display thumbnail.
                cell.insertSubview(imageView, atIndex: 0)
                cell.bringSubviewToFront(cell.titleBackgroundView)
                cell.bringSubviewToFront(cell.titleLabel)
                
                cell.photoView = imageView
            }
        }
    }
	
	// Get photo with given index path.
	private func getPhotoAtIndex(indexPath indexPath: NSIndexPath) -> PhotoModel {
		return getPhotoAtIndex(index: indexPath.row)
	}
	
	// Get photo at given index.
	private func getPhotoAtIndex(index index: Int) -> PhotoModel {
		return photos[index]
	}
	
	// Switch collection sort; taken / rating.
	func switchSort() {
		if (collectionSort != PhotoModel.Sort.taken) {
			collectionSort = PhotoModel.Sort.taken
		} else {
			collectionSort = PhotoModel.Sort.rating
		}
		
		loadPhotos()
	}
	
	// MARK: Notifications
	
	// Receive notification when photos are downloaded or updated.
	func onPhotosUpdate(notification: NSNotification) {
		loadPhotos()
	}
}
