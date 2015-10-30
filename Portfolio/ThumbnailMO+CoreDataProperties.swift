//
//  Thumbnails+CoreDataProperties.swift
//  just Radovan
//
//  Created by Radovan on 30/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ThumbnailMO {

    @NSManaged var photoID: NSNumber
    @NSManaged var url: String
    @NSManaged var size: NSNumber
}
