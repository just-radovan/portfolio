//
//  Photos+CoreDataProperties.swift
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

extension PhotoMO {

    @NSManaged var id: NSNumber
    @NSManaged var title: String
    @NSManaged var desc: String?
    @NSManaged var width: NSNumber?
    @NSManaged var height: NSNumber?
    @NSManaged var photoURL: String?
    @NSManaged var rating: NSNumber?
    @NSManaged var ratingHigh: NSNumber?
    @NSManaged var nsfw: NSNumber?
    @NSManaged var taken: NSDate?
    @NSManaged var focalLength: String?
    @NSManaged var shutterSpeed: String?
    @NSManaged var iso: String?
    @NSManaged var aperture: String?
    @NSManaged var camera: String?
    @NSManaged var lens: String?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var downloaded: NSDate?
}
