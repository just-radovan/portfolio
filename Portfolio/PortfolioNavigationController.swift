//
//  PortfolioNavigationController.swift
//  just Radovan
//
//  Created by Radovan on 28/11/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit

class PortfolioNavigationController: UINavigationController {
    
    var defaultBarStyle: UIBarStyle?
    var defaultTintColor: UIColor?

    // Switch navigation bar to black.
    func setBlackNavigationBar() {
        if (defaultBarStyle == nil) {
            defaultBarStyle = self.navigationBar.barStyle
        }
        if (defaultTintColor == nil) {
            defaultTintColor = self.navigationBar.tintColor
        }
        
        self.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        self.navigationBar.tintColor = UIColor.lightGrayColor()
    }
    
    // Switch navigation bar to white.
    func setWhiteNavigationBar() {
        print("White")
        
        self.navigationBar.barStyle = defaultBarStyle!
        self.navigationBar.tintColor = defaultTintColor!
    }
}
