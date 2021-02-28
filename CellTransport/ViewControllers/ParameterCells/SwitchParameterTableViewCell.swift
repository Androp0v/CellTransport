//
//  SwitchParameterTableViewCell.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class SwitchParameterTableViewCell: BaseParameterTableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchItem: UISwitch!
    @IBAction func setSwitchValue(_ sender: Any) {

        guard let valueSetter = valueSetter else {
            NSLog("Could not set value")
            fetchParameterValue()
            return
        }

        // Set value and save return bool (flags wether a restart is required or not)
        var needsRestart = false
        if switchItem.isOn {
            needsRestart = valueSetter("true")
        } else {
            needsRestart = valueSetter("false")
        }
        // If a restart is required, text should be red
        if needsRestart {
            titleLabel.textColor = .systemRed
        } else {
            titleLabel.textColor = .label
            // Call updateValue to retrieve the converted value in case of error
            fetchParameterValue()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public func setTitleLabel(text: String) {
        titleLabel.text = text
    }
    override public func fetchParameterValue() {
        guard let valueGetter = valueGetter else { return }
        if valueGetter() == "true" {
            switchItem.isOn = true
        } else {
            switchItem.isOn = false
        }
    }

}
