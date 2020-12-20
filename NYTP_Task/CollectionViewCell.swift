//
//  CollectionViewCell.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.itemImageView.image = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.itemImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.itemImageView.layer.cornerRadius = 8
    }
    
    var imageId: Int = 0 {
        didSet {
            let imageUrlText = "https://picsum.photos/300/200?image=\(self.imageId)"
            self.itemImageView.assignImage(from: imageUrlText)
        }
    }
    
}
