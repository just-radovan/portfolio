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
        self.id = NSNumber(int: photoModel.id)
        self.title = photoModel.title
        self.desc = photoModel.desc
        self.width = photoModel.width
        self.height = photoModel.height
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
    }
}