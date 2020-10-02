//
//  ParametersViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController, MotorPickerDelegate, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet var nCells: UITextField!
    @IBOutlet var nParticlesPerCell: UITextField!
    @IBOutlet var nBodies: UILabel!
    @IBOutlet var nMicrotubules: UITextField!
    @IBOutlet weak var wON: UITextField!
    @IBOutlet weak var wOFF: UITextField!
    @IBOutlet weak var viscosity: UITextField!
    @IBOutlet weak var motorPickerButton: UIButton!
    
    var selectedMotorFromPicker: Int32 = 0
    var motorPickerViewController: MotorPickerController = MotorPickerController()
    
    @IBAction func motorPickerButtonPressed(_ sender: Any) {
        motorPickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "MotorPickerViewControllerID") as! MotorPickerController
        motorPickerViewController.modalPresentationStyle = .popover
        motorPickerViewController.popoverPresentationController?.sourceView = motorPickerButton
        motorPickerViewController.presentationController?.delegate = self
        motorPickerViewController.delegate = self
        self.present(motorPickerViewController, animated: true, completion: nil)

    }
    
    // Called when motorPickerViewControlled is dismissed
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
        switch selectedMotorFromPicker {
        case parameters.KINESIN_ONLY:
            motorPickerButton.setTitle("Kinesins", for: .normal)
        case parameters.DYNEIN_ONLY:
            motorPickerButton.setTitle("Dyneins", for: .normal)
        default:
            motorPickerButton.setTitle("Kinesins", for: .normal)
        }
        
        parameters.molecularMotors = selectedMotorFromPicker
    }
    
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
    
    @IBAction func viscosityChanged(_ sender: Any) {
        // Check that the input value is a number
        if Float(String(viscosity.text!)) != nil {
            // Set parameter used in the simulation
            parameters.n_w = Float(String(viscosity.text!))!
            // Rewrite the text in the textfield to properly format numbers without decimal separator
            viscosity.text = String(parameters.n_w)
        } else {
            // Default the textfield text to the previous valid value
            viscosity.text = String(parameters.n_w)
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
    
    func motorSelected(molecularMotor: Int32) {
        selectedMotorFromPicker = molecularMotor
    }
    
    func doneButtonPressed() {
        self.presentationControllerDidDismiss(motorPickerViewController.presentationController!)
        motorPickerViewController.dismiss(animated: true, completion: nil)
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
