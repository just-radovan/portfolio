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
    var name: String
    var description: String?
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
    var pageUrl: String?
    // EXIF
    var taken: NSDate?
    var focalLength: Int?
    var shutterSpeed: Float?
    var aperture: Float?
    var iso: Int?
    var camera: String?
    var lens: String?
    // Geolocation
    var latitude: Double?
    var longitude: Double?
    
    init(id: Int32, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }
}