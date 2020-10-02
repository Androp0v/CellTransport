//
//  MotorPickerController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 2/10/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

protocol MotorPickerDelegate: class {
    func motorSelected(molecularMotor: Int32)
    func doneButtonPressed()
}

class MotorPickerController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var motorPicker: UIPickerView!
    @IBAction func pickDone(_ sender: Any) {
        delegate?.doneButtonPressed()
    }
    
    let pickerOptions: [String] = ["Kinesins", "Dyneins"]
    
    weak var delegate: MotorPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set popover size
        self.preferredContentSize = CGSize(width: 250, height: 150)
        
        // Set motorPicker delegate
        self.motorPicker.delegate = self
        self.motorPicker.dataSource = self
        
        // Select current row
        switch parameters.molecularMotors {
        case parameters.KINESIN_ONLY:
            motorPicker.selectRow(0, inComponent: 0, animated: false)
        case parameters.DYNEIN_ONLY:
            motorPicker.selectRow(1, inComponent: 0, animated: false)
        default:
            motorPicker.selectRow(0, inComponent: 0, animated: false)
        }
    }
    
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        var motorID: Int32 = 0
        
        switch row {
        case 0:
            motorID = parameters.KINESIN_ONLY
        case 1:
            motorID = parameters.DYNEIN_ONLY
        default:
            motorID = parameters.KINESIN_ONLY
        }
        delegate?.motorSelected(molecularMotor: motorID)
    }

}
