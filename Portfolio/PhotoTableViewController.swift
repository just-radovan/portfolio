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
    var photos = [PhotoModel]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        dateFormatter.dateFormat = "HH:mm dd.MM.yyyy"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let downloader = PhotoDownloader()
        downloader.downloadList { list in
            if let photos = list {
                self.photos = photos
                
                for photo in self.photos {
                    downloader.downloadDetail(photo) { detail in
                        if let completedPhoto = detail, let index = photos.indexOf(photo) {
                            self.photos[index] = completedPhoto
                            self.tableView.reloadData()
                        }
                    }
                }
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
                cell.thumbnailImage.af_setImageWithURL(NSURL(string: thumbnails[0].url)!)
            }
        }
        
        return cell
    }
}
