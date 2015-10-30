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
    func fill(photoModel: PhotoModel, thumbnailModel: ThumbnailModel) {
        self.photoID = NSNumber(int: photoModel.id)
        self.size = thumbnailModel.size
        self.url = thumbnailModel.url
    }
}
