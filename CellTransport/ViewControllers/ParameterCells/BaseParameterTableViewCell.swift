//
//  BaseParameterTableViewCell.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 27/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

protocol BaseParameterTableViewCellDelegate: class {
    func mayRequireRestart()
}

class BaseParameterTableViewCell: UITableViewCell {

    // Returns the value of the associated property
    public var valueGetter: (() -> String?)?
    public var valueSetter: ((String) -> Bool)?

    // Delegate
    public weak var delegate: BaseParameterTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public func fetchParameterValue() {
        // Implemented on the subclasses
    }

}
