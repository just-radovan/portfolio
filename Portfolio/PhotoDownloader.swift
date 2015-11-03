//
//  PhotoDownloader.swift
//  Portfolio
//
//  Created by Radovan on 27/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension NSURLSessionTask {
    func start(){
        self.resume()
    }
}

class PhotoDownloader {
    
    let dataController = DataController()
    let dateFormatter = NSDateFormatter()
    let photoBaseUrl = "https://api.500px.com/v1/photos"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // 2015-08-11T18:20:33-04:00
    }
    
    // Download all new photos and it's details.
    func downloadAll(completion: (downloadedPhotos: Int) -> Void) {
        let downloader = PhotoDownloader()
        
        var checked = 0 // Checked photos.
        var saved = 0 // Newly saved photos.
        
        downloader.downloadList { photos in
            if photos == nil || photos!.count == 0 {
                return
            }
            
            for photo in photos! {
                if self.dataController.photoExists(photo.id) {
                    if (checked >= photos!.count) {
                        completion(downloadedPhotos: saved)
                    }
                    
                    checked += 1
                } else {
                    self.dataController.saveOrUpdatePhoto(photo)
                    
                    saved += 1
                    checked += 1
                    
                    if (checked >= photos!.count) {
                        completion(downloadedPhotos: saved)
                    }
                    
                }
            }
        }
    }
    
    // Download photo list.
    func downloadList(completion: (result: [PhotoModel]?) -> Void) {
        let photos = [PhotoModel]()
        downloadList(1, photos: photos, completion: completion)
    }
    
    // Download photo list. Add the page to given list of phot models.
    func downloadList(page: Int, var photos: [PhotoModel], completion: (result: [PhotoModel]?) -> Void) {
        let params = [
            "feature": "user",
            "username": "just_radovan",
            "sort": "taken_at",
            "image_size[0]": String(ThumbnailSizeEnum.THUMB.rawValue),
            "image_size[1]": String(ThumbnailSizeEnum.FULL.rawValue),
            "page": String(page),
            "consumer_key": Config.consumerKey
        ]
        
        Alamofire.request(.GET, photoBaseUrl, parameters: params).responseString { response in
            if let data = response.result.value {
                if let json = self.getJSONFromString(data) {
                    // Get basic data and list.
                    let photosOnPage = json["photos"].count
                    let currentPage = json["current_page"].intValue
                    let totalPages = json["total_pages"].intValue
                    
                    print("Obtained list .. page \(currentPage) of \(totalPages) with \(photosOnPage) photos.")
                    
                    // Append photos from list to all.
                    let list = self.parseListJSON(json)
                    photos.appendContentsOf(list)
                    
                    // Check how many photos are new.
                    var photosExists = 0
                    for photo in list {
                        if self.dataController.photoExists(photo.id) {
                            photosExists += 1
                        }
                    }
                    
                    if (page < totalPages && photosOnPage > photosExists) {
                        // If there is another page with new photos, download it.
                        self.downloadList(page + 1, photos: photos, completion: completion)
                    } else {
                        // Everything downloaded, send the result.
                        completion(result: photos)
                    }
                }
            } else {
                print("No response from 500px server.")
            }
        }
    }
    
    // Create JSON from given String.
    func getJSONFromString(data: String) -> JSON? {
        if let dataFromString = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return JSON(data: dataFromString)
        }
        
        return nil
    }
    
    // Parse downloaded JSON into array of PhotoModels.
    func parseListJSON(json: JSON) -> [PhotoModel] {
        var photos = [PhotoModel]()
        
        for (_, element):(String, JSON) in json["photos"] {
            var photo = PhotoModel(
                id: element["id"].int64Value,
                title: element["name"].stringValue,
                desc: element["description"].stringValue
            )
            
            // Photo
            photo.width = element["width"].int32Value
            photo.height = element["height"].int32Value
            photo.photoUrl = element["image_url"].stringValue
            // 500px
            photo.rating = element["rating"].floatValue
            photo.ratingHigh = element["highest_rating"].floatValue
            photo.nsfw = element["nsfw"].boolValue
            // Thumbnails
            photo.thumbnails = [ThumbnailModel]()
            for (_, elementThumbnail):(String, JSON) in element["images"] {
                let thumbnail = ThumbnailModel(
                    size: elementThumbnail["size"].int32Value,
                    url: elementThumbnail["https_url"].stringValue
                )
                photo.thumbnails?.append(thumbnail)
            }
            // EXIF
            photo.taken = dateFormatter.dateFromString(element["taken_at"].stringValue)
            photo.focalLength = element["focal_length"].stringValue
            photo.shutterSpeed = element["shutter_speed"].stringValue
            photo.aperture = element["aperture"].stringValue
            photo.iso = element["iso"].stringValue
            photo.camera = element["camera"].stringValue
            photo.lens = element["lens"].stringValue
            // Geolocation
            photo.latitude = element["latitude"].doubleValue
            photo.longitude = element["longitude"].doubleValue
            
            photos.append(photo)
        }
        
        return photos
    }
}