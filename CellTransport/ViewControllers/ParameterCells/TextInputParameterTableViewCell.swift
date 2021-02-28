//
//  TextInputParameterTableViewCell.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 27/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class TextInputParameterTableViewCell: BaseParameterTableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textInputField: UITextField!
    
    @IBAction func setValue(_ sender: Any) {

        guard let valueSetter = valueSetter else {
            NSLog("Could not set value")
            fetchParameterValue()
            return
        }

        guard let inputText = textInputField.text else {
            fetchParameterValue()
            return
        }

        // Set value and save return bool (flags wether a restart is required or not)
        let needsRestart = valueSetter(inputText)

        // If a restart is required, text should be red
        if needsRestart {
            titleLabel.textColor = .systemRed
            textInputField.textColor = .systemRed
        } else {
            titleLabel.textColor = .label
            textInputField.textColor = .label
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
        textInputField.text = valueGetter?()
    }
    
}
