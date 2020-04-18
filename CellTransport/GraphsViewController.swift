//
//  GraphsViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import simd
import SceneKit

class GraphsViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var histogramChart1: LineChart?
    @IBOutlet var histogramChart2: LineChart!
    @IBOutlet var histogramChart3: LineChart!
    @IBOutlet var histogramChart4: LineChart!
    
    var autoMerge: Bool = false
    
    @IBOutlet var switchAutoMerge: UISwitch!
    @IBAction func switchAutoMergeChanged(_ sender: Any) {
        if switchAutoMerge.isOn{
            autoMerge = true
        }else{
            autoMerge = false
        }
    }
    
    @IBAction func clearAllGraphs(_ sender: Any) {
        histogramChart1?.clearHistogram()
        histogramChart2?.clearHistogram()
        histogramChart3?.clearHistogram()
    }
    
    func getHistogramData(number: Float) -> [Float]?{
        if number == 1{
            return histogramChart1?.getHistogramData()
        }else if number == 2{
            return histogramChart2?.getHistogramData()
        }else if number == 3{
            return histogramChart3?.getHistogramData()
        }else{
            return nil
        }
    }
    
    func setHistogramData1(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int){
        histogramChart1?.drawChart(cellRadius: cellRadius, distances: distances, nBodies: nBodies, autoMerge: autoMerge)
    }
    
    func setHistogramData2(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int){
        histogramChart2?.drawChart(cellRadius: cellRadius, distances: distances, nBodies: nBodies, autoMerge: false)
    }
    
    func setHistogramData3(cellRadius: Float, points: [SCNVector3]){
        histogramChart3?.drawChart(cellRadius: cellRadius, points: points, autoMerge: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 126, left: 1, bottom: 1, right: 1)
        
        histogramChart1?.layer.cornerRadius = 8.0
        histogramChart2?.layer.cornerRadius = 8.0
        histogramChart3?.layer.cornerRadius = 8.0
        histogramChart4?.layer.cornerRadius = 8.0
    }
    
}
