//
//  AppDelegate.swift
//  Portfolio
//
//  Created by Radovan on 26/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let dataController = DataController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Configure NSURLCache: 32 MB in memory, 512 MB on disk.
        let URLCache = NSURLCache(memoryCapacity: 32 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024, diskPath: nil)
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

