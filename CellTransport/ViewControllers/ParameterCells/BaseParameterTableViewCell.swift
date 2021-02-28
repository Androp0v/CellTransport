//
//  BaseParameterTableViewCell.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 27/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class BaseParameterTableViewCell: UITableViewCell {

    // Returns the value of the associated property
    public var valueGetter: (() -> String?)?
    public var valueSetter: ((String) -> Bool)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public func fetchParameterValue() {
        // Implemented on the subclasses
    }

}
