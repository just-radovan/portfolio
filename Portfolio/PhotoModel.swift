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
    var id: Int32
    var title: String
    var desc: String?
    // Photo
    var width: Int?
    var height: Int?
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
    
    init(id: Int32, title: String, desc: String) {
        self.id = id
        self.title = title
        self.desc = desc
    }
}

extension PhotoModel: Equatable {}
func ==(lhs: PhotoModel, rhs: PhotoModel) -> Bool {
    return lhs.id == rhs.id
}