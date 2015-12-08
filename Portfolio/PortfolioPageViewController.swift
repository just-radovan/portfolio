//
//  PortfolioPageViewController.swift
//  just Radovan
//
//  Created by Radovan on 11.11.15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit

class PortfolioPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	let PAGE_COLLECTION = 0;
	let PAGE_MAP = 1;
	
    let pageCount = 2
    var currentPage = 0;
    var nextPage = 0;
	var sortButtonItem: UIBarButtonItem?;
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.whiteColor()
        self.dataSource = self
        self.delegate = self
		
		sortButtonItem = UIBarButtonItem(
			title: "Sort",
			style: UIBarButtonItemStyle.Plain,
			target: self,
			action: Selector("onSortButtonPressed:")
		)
        
        switchToPage(PAGE_COLLECTION)
    }
    
    // MARK: Actions
    
    // On UISegmentedControl page changed.
    @IBAction func onSegmentChanged(sender: UISegmentedControl) {
        switchToPage(sender.selectedSegmentIndex)
    }
	
	// Initiate collection sort change.
	@IBAction func onSortButtonPressed(sender: AnyObject?) {
		if let collection = self.viewControllers![PAGE_COLLECTION] as? PhotoCollectionViewController {
			collection.switchSort()
		}
	}
    
    // MARK: Pages
    
    // Display page on given index.
    func switchToPage(index: Int) {
        var direction: UIPageViewControllerNavigationDirection
        
        if (index > currentPage) {
            direction = .Forward
        } else {
            direction = .Reverse
        }
        
        self.setViewControllers(
            [viewControllerAtIndex(index)!],
            direction: direction,
            animated: true,
            completion: nil
        )
		
		if (index == PAGE_COLLECTION) {
			self.navigationItem.rightBarButtonItem = sortButtonItem
		} else {
			self.navigationItem.rightBarButtonItem = nil
		}
		
        currentPage = index
    }
    
    /* Implement these to show "dots"...
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageCount
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    */
    
    // Instantiate UIViewController for given page index.
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        switch index {
        case PAGE_COLLECTION:
            return self.storyboard?.instantiateViewControllerWithIdentifier("PhotoCollectionViewController")
        case PAGE_MAP:
            return self.storyboard?.instantiateViewControllerWithIdentifier("MapViewController")
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
    
    // UIPageViewController is about to move to another page.
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        nextPage = getCurrentIndex(pendingViewControllers[0])
    }
    
    // Receive page transition changes.
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (completed) {
            currentPage = nextPage
            segmentedControl.selectedSegmentIndex = currentPage
        }
    }
    
    // Get page index for given UIViewController.
    func getCurrentIndex(viewController: UIViewController) -> Int {
        if let _ = viewController as? PhotoCollectionViewController {
            return PAGE_COLLECTION
        } else if let _ = viewController as? MapViewController {
            return PAGE_MAP
        }
        
        return -1
    }
}