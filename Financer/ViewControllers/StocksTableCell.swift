//
//  StocksTableCell.swift
//  Financer
//
//  Created by Никита Раташнюк on 01.03.2021.
//

import UIKit

class StocksTableCell: UITableViewCell {
    @IBOutlet var tickerLabel: UILabel!
    @IBOutlet var companyNameLabel: UILabel!
    @IBOutlet var currentPriceLabel: UILabel!
    @IBOutlet var dayShiftLabel: UILabel!
    @IBOutlet var companyImage: UIImageView!
    @IBOutlet var favouriteButton: UIButton!
    var delegate: FavouriteDelegate?
    var stock: Stock!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        companyImage.layer.cornerRadius = 20
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onStarClicked(_ sender: Any) {
        delegate?.modifyFavourites(stock: stock)
    }
}
