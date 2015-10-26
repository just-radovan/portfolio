//
//  ThumbnailModel.swift
//  Portfolio
//
//  Created by Radovan on 26/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation

class ThumbnailModel {
    
    var size: Int
    var url: String
    
    init(size: Int, url: String) {
        self.size = size
        self.url = url
    }
}