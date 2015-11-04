//
//  PhotoTableViewCell.swift
//  Portfolio
//
//  Created by Radovan on 29/10/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import AlamofireImage

class PhotoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var takenLabel: UILabel!
    
    var requestReceipt: RequestReceipt?
}