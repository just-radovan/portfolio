//
//  DataController.swift
//  just Radovan
//
//  Created by Radovan on 30/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    var managedObjectContext: NSManagedObjectContext
    
    init() {
        guard let modelURL = NSBundle.mainBundle().URLForResource("PhotosCoreData", withExtension:"momd") else {
            fatalError("Error loading data model from bundle.")
        }
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from '\(modelURL)'.")
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = coordinator
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let docURL = urls[urls.endIndex-1]
            
            let storeURL = docURL.URLByAppendingPathComponent("PhotosCoreData.sqlite")
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            } catch {
                fatalError("Error migrating store '\(error)'.")
            }
        }
    }
    
    // Check whether photo with given ID exists. If yes, update. Otherwise, create new entry.
    func saveOrUpdatePhoto(photoModel: PhotoModel) {
        let id = photoModel.id
        
        let predicate = NSPredicate(format: "id = %d", id)
        let request = NSFetchRequest(entityName: "Photos")
        request.fetchLimit = 1
        request.predicate = predicate
        
        var results: [PhotoMO]?
        do {
            results = try managedObjectContext.executeFetchRequest(request) as? [PhotoMO]
        } catch {
            print("Failed to load photo #\(id).")
        }
        
        if (results != nil && results!.count > 0 ) {
            results![0].fill(photoModel)
        } else {
            let photoMO = NSEntityDescription.insertNewObjectForEntityForName(
                "Photos", inManagedObjectContext: managedObjectContext) as! PhotoMO
            photoMO.fill(photoModel)
            
            if let thumbnails = photoModel.thumbnails {
                for thumbnail in thumbnails {
                    let thumbnailMO = NSEntityDescription.insertNewObjectForEntityForName(
                        "Thumbnails", inManagedObjectContext: self.managedObjectContext) as! ThumbnailMO
                    thumbnailMO.fill(photoModel, thumbnailModel: thumbnail)
                }
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error).")
        }
    }
}
