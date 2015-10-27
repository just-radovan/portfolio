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
        let params = ["feature": "user", "username": "just_radovan", "consumer_key": Config.consumerKey]
        
        Alamofire.request(.GET, photoBaseUrl, parameters: params).responseString { response in
            if let json = response.result.value {
                let photos = self.parseListJSON(json)
                completion(result: photos)
            }
        }
    }
    
    // Download photo detail.
    func downloadDetail(photo: PhotoModel, completion: (result: PhotoModel?) -> Void) {
        let params = ["consumer_key": Config.consumerKey]
        
        Alamofire.request(.GET, "\(photoBaseUrl)/\(photo.id)", parameters: params).responseString { response in
            if let json = response.result.value {
                let photo = self.parseDetailJSON(json, photo: photo)
                completion(result: photo)
            }
        }
    }
    
    // Parse downloaded data into array of PhotoModels.
    func parseListJSON(json: String) -> [PhotoModel] {
        var photos = [PhotoModel]()
        
        if let dataFromString = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
            
            for (_, photo):(String, JSON) in json["photos"] {
                var photo = self.createPhotoFromJSON(photo)
                
                // Photo
                photo.width = json["width"].intValue
                photo.height = json["height"].intValue
                photo.photoUrl = json["image_url"].stringValue
                // 500px
                photo.rating = json["rating"].floatValue
                photo.nsfw = json["nsfw"].boolValue
                
                photos.append(photo)
            }
        }
        
        return photos
    }
    
    // Parse downloaded data into given PhotoModel.
    func parseDetailJSON(json: String, var photo: PhotoModel) -> PhotoModel {
        if let dataFromString = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
            
            // Thumbnails
            // TODO: Load thumbnails.
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
        }

        return photo
    }

    // Create PhotoModel instance from given segment of JSON.
    func createPhotoFromJSON(json: JSON) -> PhotoModel {
        return PhotoModel(
            id: json["id"].int32Value,
            title: json["name"].stringValue,
            desc: json["description"].stringValue
        )
    }
}