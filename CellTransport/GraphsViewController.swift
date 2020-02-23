//
//  GraphsViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import simd

class GraphsViewController: UIViewController {
    
    @IBOutlet var histogramChart1: LineChart?
    @IBOutlet var histogramChart2: LineChart!
    
    
    @IBAction func clearAllGraphs(_ sender: Any) {
        histogramChart1?.clearHistogram()
        histogramChart2?.clearHistogram()
    }
    
    func setHistogramData1(cellRadius: Float, distances: UnsafeMutablePointer<Float>){
        histogramChart1?.drawChart(cellRadius: cellRadius, distances: distances)
    }
    
    func setHistogramData2(cellRadius: Float, distances: UnsafeMutablePointer<Float>){
        histogramChart2?.drawChart(cellRadius: cellRadius, distances: distances)
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
