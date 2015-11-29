//
//  AppDelegate.swift
//  Portfolio
//
//  Created by Radovan on 26/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import AlamofireImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let dataController = DataController()
    var imageCache: AutoPurgingImageCache
    var imageDownloader: ImageDownloader
    
    required override init() {
        imageCache = AutoPurgingImageCache(
            memoryCapacity: 100 * 1024 * 1024,
            preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
        )
        imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .FIFO,
            maximumActiveDownloads: 4,
            imageCache: imageCache
        )
        
        super.init()
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Configure NSURLCache: 32 MB in memory, 512 MB on disk.
        let URLCache = NSURLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024,
            diskPath: nil
        )
        NSURLCache.setSharedURLCache(URLCache)
        
        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        let downloader = PhotoDownloader()
        downloader.refresh() { downloadedPhotos in
            print("App refreshed photos; \(downloadedPhotos)")
        }
        
        downloader.refreshAllDetails()
    }
}

