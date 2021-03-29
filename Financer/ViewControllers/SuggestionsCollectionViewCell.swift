//
//  SuggestionsCollectionViewCell.swift
//  Financer
//
//  Created by Никита Раташнюк on 20.03.2021.
//

import UIKit

class SuggestionsCollectionViewCell: UICollectionViewCell {
    
    private let reuseID = "collectionCell"
    @IBOutlet var tickerButton: UIButton!
    var delegate: SuggestDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 20
        self.backgroundColor = UIColor(hex: "#F0F4F7")
    }
    
    func styleItem(text: String) {
        tickerButton.setTitle(text, for: .normal)
    }
    
    @IBAction func onSuggestTapped(_ sender: Any) {
        delegate?.modifySearchBar(s: tickerButton.currentTitle!)
    }
}
