//
//  Thumbnails.swift
//  just Radovan
//
//  Created by Radovan on 30/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation
import CoreData


class ThumbnailMO: NSManagedObject {

    // Create managed object from data model.
    func fill(thumbnailModel: ThumbnailModel, photoModel: PhotoModel) {
        self.photoID = NSNumber(longLong: photoModel.id)
        self.size = NSNumber(int: thumbnailModel.size)
        self.url = thumbnailModel.url
    }
    
    // Create data model from managed object.
    func getThumbnailModel() -> ThumbnailModel {
        return ThumbnailModel(size: self.size.intValue, url: self.url)
    }
}