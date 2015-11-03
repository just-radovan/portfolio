//
//  PhotoDetailViewController.swift
//  just Radovan
//
//  Created by Radovan on 01/11/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import AlamofireImage

class PhotoDetailViewController: UIViewController {

    let dataController = DataController()
    var photo: PhotoModel?
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    
    @IBOutlet weak var photoImageView: UIImageView!
    
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
        
        if let photo = photo, thumbnail = photo.getThumbnailForSize(.FULL) {
            print("Thumbnail \(ThumbnailSizeEnum.FULL): \(thumbnail.url)")
            
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
