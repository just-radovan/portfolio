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
    
    let photoListUrl = "https://api.500px.com/v1/photos"
    let photoListParameters = ["feature": "user", "username": "just_radovan", "consumer_key": Config.consumerKey]
    
    // Download photo list.
    func downloadList() {
        Alamofire.request(.GET, photoListUrl, parameters: photoListParameters)
            .responseString { response in
                if let json = response.result.value {
                    self.parseJSON(json)
                }
        }
    }
    
    // Download photo detail.
    func downloadPhotoDetail(id: Int32, photo: PhotoModel) -> PhotoModel {
        // TODO: Download detail.
        // TODO: Fill properties within PhotoModel.
        
        return photo
    }
    
    // Parse downloaded data into array of PhotoModels.
    func parseJSON(json: String) -> [PhotoModel]? {
        var photos = [PhotoModel]()
        
        if let dataFromString = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)

            for (_, photo):(String, JSON) in json["photos"] {
                photos.append(self.createPhotoFromJSON(photo))
            }
        }
        
        return photos
    }
    
    // Create PhotoModel instance from given segment of JSON.
    func createPhotoFromJSON(json: JSON) -> PhotoModel {
        var photo = PhotoModel(
            id: json["id"].int32Value,
            name: json["name"].stringValue,
            description: json["description"].stringValue
        )
        // Photo
        photo.width = json["width"].intValue
        photo.height = json["height"].intValue
        photo.photoUrl = json["image_url"].stringValue
        // 500px
        photo.rating = json["rating"].floatValue
        photo.nsfw = json["nsfw"].boolValue
        
        return photo
    }
}