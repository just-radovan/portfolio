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
            
            print("CoreData init finished...")
        }
    }
    
    // MARK: Managed objects
    func photoExists(id: Int64) -> Bool {
        let request = NSFetchRequest(entityName: "Photos")
        request.predicate = NSPredicate(format: "id = %d", id)
        request.fetchLimit = 1 // There should be only one photo with given ID
        
        var error: NSError?
        let items = managedObjectContext.countForFetchRequest(request, error: &error) as Int
        if (error != nil) {
            print("Failed to check whether photo #\(id) exists.")
        }
        
        return items > 0
    }
    
    // Get photo (managed object) with given ID
    func getPhotoByID(id: Int64) -> PhotoMO? {
        let request = NSFetchRequest(entityName: "Photos")
        request.predicate = NSPredicate(format: "id = %d", id)
        request.fetchLimit = 1 // There should be only one photo with given ID
        
        var results: [PhotoMO]?
        do {
            results = try managedObjectContext.executeFetchRequest(request) as? [PhotoMO]
        } catch {
            print("Failed to load photo #\(id).")
        }
        
        if (results != nil && results!.count > 0) {
            return results![0]
        }
        return nil
    }
    
    // Get thumbnail (managed object) with given photo ID and size
    func getThumbnailByIDAndSize(photoID: Int64, size: Int32) -> ThumbnailMO? {
        let request = NSFetchRequest(entityName: "Thumbnails")
        request.predicate = NSPredicate(format: "photoID = %d and #size = %d", photoID, size)
        request.fetchLimit = 1 // There should be only one thumbnail with given ID and size
        
        var results: [ThumbnailMO]?
        do {
            results = try managedObjectContext.executeFetchRequest(request) as? [ThumbnailMO]
        } catch {
            print("Failed to load thumbnail for photo #\(photoID) with size \(size).")
        }
        
        if (results != nil && results!.count > 0) {
            return results![0]
        }
        return nil
    }
    
    // Get all tumbnails (managed objects) for given photo
    func getThumbnailsForPhoto(photoMO: PhotoMO) -> [ThumbnailMO]? {
        let request = NSFetchRequest(entityName: "Thumbnails")
        request.predicate = NSPredicate(format: "photoID = %d", photoMO.id.longLongValue)
        
        var results: [ThumbnailMO]?
        do {
            results = try managedObjectContext.executeFetchRequest(request) as? [ThumbnailMO]
        } catch {
            print("Failed to load thumbnails for photo #\(photoMO.id).")
        }
        
        return results
    }
    
    // MARK: Models
	
    // Check whether photo with given ID exists. If yes, update. Otherwise, create new entry.
    func saveOrUpdatePhoto(photoModel: PhotoModel) {
        let id = photoModel.id
        
        // Photo data.
        var photoMO: PhotoMO? = getPhotoByID(id)
        if photoMO == nil {
            photoMO = NSEntityDescription.insertNewObjectForEntityForName(
                "Photos", inManagedObjectContext: managedObjectContext) as? PhotoMO
        }
        photoMO?.fill(photoModel)
        
        // Thumbnails.
        if let thumbnails = photoModel.thumbnails {
            for thumbnail in thumbnails {
                saveOrUpdateThumbnail(thumbnail, photoModel: photoModel)
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error).")
        }
    }
    
    // Check whether thumbnail with given photo ID and size exists. If yes, update. Otherwise, create new entry.
    func saveOrUpdateThumbnail(thumbnailModel: ThumbnailModel, photoModel: PhotoModel) {
        var thumbnailMO: ThumbnailMO? = getThumbnailByIDAndSize(photoModel.id, size: thumbnailModel.size)
        if thumbnailMO == nil {
            thumbnailMO = NSEntityDescription.insertNewObjectForEntityForName(
                "Thumbnails", inManagedObjectContext: managedObjectContext) as? ThumbnailMO
        }
        thumbnailMO?.fill(thumbnailModel, photoModel: photoModel)
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error).")
        }
    }
    
    // Get all photos (models)
	func getPhotos() -> [PhotoModel]? {
		return getPhotos(sort: nil)
	}
	
	// Get all photos (models)
	func getPhotos(sort sort: PhotoModel.Sort?) -> [PhotoModel]? {
        let request = NSFetchRequest(entityName: "Photos")
		
		let defaultSort = NSSortDescriptor(key: "taken", ascending: false)
		if (sort == nil) {
			request.sortDescriptors = [defaultSort]
		} else {
			request.sortDescriptors = [NSSortDescriptor(key: sort!.rawValue, ascending: sort!.isAscending(sort!)), defaultSort]
		}
		
        var results: [PhotoMO]?
        do {
            results = try managedObjectContext.executeFetchRequest(request) as? [PhotoMO]
        } catch let error as NSError {
            print("Failed to load photos; error: \(error.code)")
        }
        
        if (results != nil) {
            var models = [PhotoModel]()
            for photoMO in results! {
                var photoModel = photoMO.getPhotoModel();
                
                // Load thumbnails.
                if let thumbnails = getThumbnailsForPhoto(photoMO) {
                    photoModel.thumbnails = [ThumbnailModel]()
                    
                    for thumbnailMO in thumbnails {
                        photoModel.thumbnails!.append(thumbnailMO.getThumbnailModel())
                    }
                }
                
                // Add to photos array.
                models.append(photoModel)
            }
            
            return models
        }
        
        return nil
    }
}
