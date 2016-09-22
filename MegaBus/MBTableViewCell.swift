//
//  MBTableViewCell.swift
//  MegaBus
//
//  Created by Javier Fuchs on 9/20/16.
//  Copyright © 2016 Fuchs. All rights reserved.
//

import UIKit

class MBTableViewCell: UITableViewCell {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    /// Always hide info first
    func configure() {
        logoImageView.alpha = 0
        priceLabel.text = ""
        scheduleLabel.text = ""
        durationLabel.text = ""
    }
    
    /// Configure the information with the instance of MBTravel
    func configure(travel: MBTravel) {
        
        self.configure()
        
        if let iconName = travel.provider_logo,
           let icon63 = iconName.stringByReplacingOccurrencesOfString("{size}", withString: "63") as String?,
            let url = NSURL.init(string: icon63) {
            self.logoImageView.alpha = 1
            self.logoImageView.setImageWithURL(url)
        }
        self.priceLabel.text = "€\(travel.price_in_euros)"
        self.scheduleLabel.text = travel.schedule()
        self.durationLabel.text = travel.duration()
    }
    
    /// Handy static method to return the reuse id for cells
    class func reuseIdentifier() -> String {
        return "MBTableViewCell"
    }
}
