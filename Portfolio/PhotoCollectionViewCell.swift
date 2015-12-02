//
//  PhotoCollectionViewCell.swift
//  just Radovan
//
//  Created by Radovan on 02/12/15.
//  Copyright © 2015 just Radovan. All rights reserved.
//

import UIKit
import AlamofireImage

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleBackgroundView: UIView!

    var photoId: Int64?
    var requestReceipt: RequestReceipt?
    var photoView: UIImageView?
}
