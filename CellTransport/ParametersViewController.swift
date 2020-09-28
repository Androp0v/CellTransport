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
    
    @IBOutlet weak var collisionsSwitch: UISwitch!
    @IBAction func collisionsSwitchChange(_ sender: Any) {
        if collisionsSwitch.isOn == true {
            parameters.collisionsFlag = true
        } else {
            parameters.collisionsFlag = false
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
