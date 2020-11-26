//
//  ComputeViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 24/11/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import simd

class ComputeViewController: UIViewController {
    
    public var MTcollection: [[simd_float3]]?
    private var hasComputedPersistenceLenght = false
    
    @IBOutlet weak var computedPersistenceLenght: UILabel!
    @IBAction func computePersistenceLenght(_ sender: Any) {
        
        if !hasComputedPersistenceLenght && self.MTcollection != nil {
            
            // Set hasComputedPersistenceLenght to true so a new computation is never started
            hasComputedPersistenceLenght = true
            
            DispatchQueue.global().async {
                let bins: Int = 100
                var currentCosineArray = [Float](repeating: 0, count: bins)
                var currentCosineCount = [Int](repeating: 0, count: bins)
                
                for MTpoints in self.MTcollection! {
                    let newCosineResult = expectedValueCosine(points: MTpoints, bins: bins)
                    let newCosineArray = newCosineResult.0
                    let newCosineCount = newCosineResult.1
                    currentCosineArray = zip(currentCosineArray, newCosineArray).map(+)
                    currentCosineCount = zip(currentCosineCount, newCosineCount).map(+)
                }
                
                var logCosineArray = [Float](repeating: 0, count: bins)
                for i in 0..<bins {
                    currentCosineArray[i] /= Float(currentCosineCount[i])
                    if currentCosineCount[i] < 500 {
                        currentCosineArray[i] = 0
                    }
                    if currentCosineArray[i] < 0 {
                        currentCosineArray[i] = 0
                    }
                    logCosineArray[i] = log(currentCosineArray[i])
                }
                
                var usablePoints: [Double] = []
                for i in 0..<bins {
                    if logCosineArray[i].isFinite {
                        usablePoints.append(Double(logCosineArray[i]))
                    } else {
                        break
                    }
                }
                var usableDistances: [Double] = []
                for i in 0..<usablePoints.count {
                    usableDistances.append(Double(i) * Double(Float(parameters.maxNSegments) * parameters.microtubuleSegmentLength) / Double(bins))
                }
                
                DispatchQueue.main.async {
                    print(usablePoints)
                    print(usableDistances)
                    self.computedPersistenceLenght.text = String( -1/linearRegression(usableDistances, usablePoints) ) + " nm"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
