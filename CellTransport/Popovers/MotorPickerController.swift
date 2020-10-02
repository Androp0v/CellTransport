//
//  MotorPickerController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 2/10/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class MotorPickerController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var motorPicker: UIPickerView!
    
    let pickerOptions: [String] = ["Kinesins", "Dyneins"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set popover size
        self.preferredContentSize = CGSize(width: 250, height: 100)
        
        // Set motorPicker delegate
        self.motorPicker.delegate = self
        self.motorPicker.dataSource = self
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
    }

}
