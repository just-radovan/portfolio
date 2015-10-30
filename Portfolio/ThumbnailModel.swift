//
//  ThumbnailModel.swift
//  Portfolio
//
//  Created by Radovan on 26/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import Foundation

struct ThumbnailModel {
    
    var size: Int32
    var url: String
    
    init(size: Int32, url: String) {
        self.size = size
        self.url = url
    }
}