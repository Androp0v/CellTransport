//
//  ParametersViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController {
        
    @IBOutlet var nCells: UITextField!
    @IBOutlet var nParticlesPerCell: UITextField!
    @IBOutlet var nBodies: UILabel!
    @IBOutlet var nMicrotubules: UITextField!
    @IBOutlet weak var wON: UITextField!
    @IBOutlet weak var wOFF: UITextField!
    
    @IBOutlet weak var collisionsSwitch: UISwitch!
    @IBAction func collisionsSwitchChange(_ sender: Any) {
        if collisionsSwitch.isOn == true {
            parameters.collisionsFlag = true
        } else {
            parameters.collisionsFlag = false
        }
    }
    @IBAction func wONChanged(_ sender: Any) {
        // Check that the input value is a number
        if Float(String(wON.text!)) != nil {
            // Set parameter used in the simulation
            parameters.wON = Float(String(wON.text!))!
            // Rewrite the text in the textfield to properly format numbers without decimal separator
            wON.text = String(parameters.wON)
        } else {
            // Default the textfield text to the previous valid value
            wON.text = String(parameters.wON)
        }
    }
    @IBAction func wOFFChanged(_ sender: Any) {
        // Check that the input value is a number
        if Float(String(wOFF.text!)) != nil {
            // Set parameter used in the simulation
            parameters.wOFF = Float(String(wOFF.text!))!
            // Rewrite the text in the textfield to properly format numbers without decimal separator
            wOFF.text = String(parameters.wOFF)
        } else {
            // Default the textfield text to the previous valid value
            wOFF.text = String(parameters.wOFF)
        }
    }
    
    func changenCellsText(text: String){
        self.nCells.text = text
    }
    
    func changeParticlesPerCellText(text: String){
        self.nParticlesPerCell.text = text
    }
    
    func changenBodiesText(text: String){
        self.nBodies.text = text
    }
    
    func changeMicrotubulesText(text: String){
        self.nMicrotubules.text = text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if parameters.collisionsFlag == true {
            collisionsSwitch.setOn(true, animated: false)
        }else{
            collisionsSwitch.setOn(false, animated: false)
        }
        
        wON.keyboardType = .numberPad
        wON.text = String(parameters.wON)
        wOFF.keyboardType = .numberPad
        wOFF.text = String(parameters.wOFF)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
