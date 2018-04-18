//
//  TokenSaleTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/12/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class TokenSaleTableViewCell: UITableViewCell {
    @IBOutlet weak var tokenSaleImageView: UIImageView!
    @IBOutlet weak var tokenSaleNameLabel: UILabel!
    @IBOutlet weak var tokenSaleShortDescriptionLabel: UILabel!
    @IBOutlet weak var tokenSaleTimeLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    
    override func awakeFromNib() {
        tokenSaleNameLabel.theme_textColor = O3Theme.titleColorPicker
        tokenSaleTimeLabel.theme_textColor = O3Theme.lightTextColorPicker
        tokenSaleShortDescriptionLabel.theme_textColor = O3Theme.titleColorPicker
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
    
    struct TokenSaleData {
        var imageURL: String
        var name: String
        var shortDescription: String
        var time: Double
    }
    
    var tokenSaleEndDate: Date?
    
    var tokenSaleData: TokenSaleData? {
        didSet {
            tokenSaleImageView.kf.setImage(with: URL(string: tokenSaleData?.imageURL ?? ""))
            tokenSaleNameLabel.text = tokenSaleData?.name ?? ""
            tokenSaleShortDescriptionLabel.text = tokenSaleData?.shortDescription ?? ""
            tokenSaleEndDate = Date(timeIntervalSince1970: Double((tokenSaleData?.time)!))
            countDownDate()
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDownDate), userInfo: nil, repeats: true)
            
        }
    }
    
    @objc func countDownDate() {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.unitsStyle = .full
        formatter.calendar = calendar
        let string = formatter.string(from: now, to: tokenSaleEndDate!)!
        tokenSaleTimeLabel.text = String(format:"Ends in %@", string)
    }
    
}
