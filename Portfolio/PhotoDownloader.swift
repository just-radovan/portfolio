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
    
    let dateFormatter = NSDateFormatter()
    let photoBaseUrl = "https://api.500px.com/v1/photos"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // 2015-08-11T18:20:33-04:00
    }
    
    // Download photo list.
    func downloadList(completion: (result: [PhotoModel]?) -> Void) {
        let photos = [PhotoModel]()
        downloadList(1, photos: photos, completion: completion)
    }
    
    func downloadList(page: Int, var photos: [PhotoModel], completion: (result: [PhotoModel]?) -> Void) {
        let params = [
            "feature": "user",
            "username": "just_radovan",
            "page": String(page),
            "consumer_key": Config.consumerKey
        ]
        
        Alamofire.request(.GET, photoBaseUrl, parameters: params).responseString { response in
            if let data = response.result.value {
                if let json = self.getJSONFromString(data) {
                    let totalPages = json["total_pages"].intValue
                    print("Page: \(page) of \(totalPages)")
                    
                    let list = self.parseListJSON(json)
                    photos.appendContentsOf(list)
                    
                    if (page < totalPages) {
                        self.downloadList(page + 1, photos: photos, completion: completion)
                    } else {
                        completion(result: photos)
                    }
                }
            }
        }
    }
    
    // Download photo detail.
    func downloadDetail(photo: PhotoModel, completion: (result: PhotoModel?) -> Void) {
        let params = ["image_size": "2", "consumer_key": Config.consumerKey]
        
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
    
    // Parse downloaded data into array of PhotoModels.
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
    
    // Parse downloaded data into given PhotoModel.
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