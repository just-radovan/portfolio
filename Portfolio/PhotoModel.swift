//
//  PhotoModel.swift
//  Portfolio
//
//  Created by Radovan on 26/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation

struct PhotoModel {
    
    // Basic properties
    var id: Int64
    var title: String
    var desc: String?
    // Photo
    var width: Int32?
    var height: Int32?
    var photoUrl: String?
    // Thumbnails
    var thumbnails: [ThumbnailModel]?
    // 500px
    var rating: Float?
    var ratingHigh: Float?
    var nsfw: Bool?
    // EXIF
    var taken: NSDate?
    var focalLength: String?
    var shutterSpeed: String?
    var aperture: String?
    var iso: String?
    var camera: String?
    var lens: String?
    // Geolocation
    var latitude: Double?
    var longitude: Double?
    
    init(id: Int64, title: String, desc: String) {
        self.id = id
        self.title = title
        self.desc = desc
    }
    
    // Find thumbnail for given size.
    func getThumbnailForSize(size: ThumbnailSizeEnum) -> ThumbnailModel? {
        if let thumbnails = thumbnails {
            for thumbnail in thumbnails {
                if thumbnail.size == size.rawValue {
                    return thumbnail
                }
            }
        }
        
        return nil
    }
}

extension PhotoModel: Equatable {}
func ==(lhs: PhotoModel, rhs: PhotoModel) -> Bool {
    return lhs.id == rhs.id
}