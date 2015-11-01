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
                    downloader.downloadDetail(photo) { detail in
                        if let completedPhoto = detail {
                            self.dataController.saveOrUpdatePhoto(completedPhoto)
                            
                            saved += 1
                            checked += 1
                            
                            if (checked >= photos!.count) {
                                completion(downloadedPhotos: saved)
                            }
                        }
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
            "page": String(page),
            "consumer_key": Config.consumerKey
        ]
        
        Alamofire.request(.GET, photoBaseUrl, parameters: params).responseString { response in
            if let data = response.result.value {
                if let json = self.getJSONFromString(data) {
                    // Get basic data and list.
                    let photosOnPage = json["photos"].count
                    let totalPages = json["total_pages"].intValue
                    
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
            }
        }
    }
    
    // Download photo detail.
    func downloadDetail(photo: PhotoModel, completion: (result: PhotoModel?) -> Void) {
        let params = ["image_size": "4", "consumer_key": Config.consumerKey]
        
        Alamofire.request(.GET, "\(photoBaseUrl)/\(photo.id)", parameters: params).responseString { response in
            if let data = response.result.value {
                if let json = self.getJSONFromString(data) {
                    let photo = self.parseDetailJSON(json, photo: photo)
                    completion(result: photo)
                }
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
            var photo = self.createPhotoFromJSON(element)
            
            // Photo
            photo.width = json["width"].int32Value
            photo.height = json["height"].int32Value
            photo.photoUrl = json["image_url"].stringValue
            // 500px
            photo.rating = json["rating"].floatValue
            photo.nsfw = json["nsfw"].boolValue
            
            photos.append(photo)
        }
        
        return photos
    }
    
    // Parse downloaded JSON into given PhotoModel.
    func parseDetailJSON(json: JSON, var photo: PhotoModel) -> PhotoModel {
        // Thumbnails
        photo.thumbnails = [ThumbnailModel]()
        for (_, element):(String, JSON) in json["photo"]["images"] {
            let thumbnail = ThumbnailModel(
                size: element["size"].int32Value,
                url: element["url"].stringValue
            )
            photo.thumbnails?.append(thumbnail)
        }
        // 500px
        photo.ratingHigh = json["photo"]["highest_rating"].floatValue
        // EXIF
        photo.taken = dateFormatter.dateFromString(json["photo"]["taken_at"].stringValue)
        photo.focalLength = json["photo"]["focal_length"].stringValue
        photo.shutterSpeed = json["photo"]["shutter_speed"].stringValue
        photo.aperture = json["photo"]["aperture"].stringValue
        photo.iso = json["photo"]["iso"].stringValue
        photo.camera = json["photo"]["camera"].stringValue
        photo.lens = json["photo"]["lens"].stringValue
        // Geolocation
        photo.latitude = json["photo"]["latitude"].doubleValue
        photo.longitude = json["photo"]["longitude"].doubleValue
        
        return photo
    }
    
    // Create PhotoModel instance from given segment of JSON.
    func createPhotoFromJSON(json: JSON) -> PhotoModel {
        return PhotoModel(
            id: json["id"].int64Value,
            title: json["name"].stringValue,
            desc: json["description"].stringValue
        )
    }
}