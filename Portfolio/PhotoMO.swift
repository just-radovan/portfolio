//
//  Photos.swift
//  just Radovan
//
//  Created by Radovan on 30/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation
import CoreData


class PhotoMO: NSManagedObject {

    // Create managed object from data model.
    func fill(photoModel: PhotoModel) {
        self.id = NSNumber(longLong: photoModel.id)
        self.title = photoModel.title
        self.desc = photoModel.desc
        if let width = photoModel.width {
            self.width = NSNumber(int: width)
        }
        if let height = photoModel.height {
            self.height = NSNumber(int: height)
        }
        self.photoURL = photoModel.photoUrl
        self.rating = photoModel.rating
        self.ratingHigh = photoModel.ratingHigh
        self.nsfw = photoModel.nsfw
        self.taken = photoModel.taken
        self.focalLength = photoModel.focalLength
        self.shutterSpeed = photoModel.shutterSpeed
        self.aperture = photoModel.aperture
        self.iso = photoModel.iso
        self.camera = photoModel.camera
        self.lens = photoModel.lens
        self.latitude = photoModel.latitude
        self.longitude = photoModel.longitude
        self.downloaded = photoModel.downloaded
    }
    
    // Create data model from managed object.
    func getPhotoModel() -> PhotoModel {
        var photoModel = PhotoModel(id: self.id.longLongValue, title: self.title, desc: self.desc!)
        photoModel.title = self.title
        photoModel.desc = self.desc
        photoModel.width = self.width?.intValue
        photoModel.height = self.height?.intValue
        photoModel.photoUrl = self.photoURL
        photoModel.rating = self.rating?.floatValue
        photoModel.ratingHigh = self.ratingHigh?.floatValue
        photoModel.nsfw = self.nsfw?.boolValue
        photoModel.taken = self.taken
        photoModel.focalLength = self.focalLength
        photoModel.shutterSpeed = self.shutterSpeed
        photoModel.aperture = self.aperture
        photoModel.iso = self.iso
        photoModel.camera = self.camera
        photoModel.lens = self.lens
        photoModel.latitude = self.latitude?.doubleValue
        photoModel.longitude = self.longitude?.doubleValue
        photoModel.downloaded = self.downloaded
        
        return photoModel
    }
}