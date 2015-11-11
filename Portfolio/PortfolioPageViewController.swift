//
//  PortfolioPageViewController.swift
//  just Radovan
//
//  Created by Radovan on 11.11.15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit

class PortfolioPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    let pageCount = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        self.setViewControllers(
            [viewControllerAtIndex(0)!],
            direction: UIPageViewControllerNavigationDirection.Forward,
            animated: true,
            completion: nil
        )
    }
    
    // Get number of pages.
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageCount
    }
    
    // Get initial page index.
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // Instantiate UIViewController for given page index.
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        switch index {
        case 0:
            return self.storyboard?.instantiateViewControllerWithIdentifier("PhotoTableViewController")
        case 1:
            return self.storyboard?.instantiateViewControllerWithIdentifier("PhotoDetailViewController")
        default:
            return nil
        }
    }
    
    // Return ViewController at current page index +1.
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let index = getCurrentIndex(viewController)
        
        return viewControllerAtIndex(index - 1)
    }
    
    // Return ViewController at current page index -1.
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let index = getCurrentIndex(viewController)
        
        return viewControllerAtIndex(index + 1)
    }
    
    // Get page index for given UIViewController.
    func getCurrentIndex(viewController: UIViewController) -> Int {
        if let _ = viewController as? PhotoTableViewController {
            return 0
        } else if let _ = viewController as? PhotoDetailViewController {
            return 1
        }
        
        return -1
    }
}