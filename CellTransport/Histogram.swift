//
//  Histogram.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 14/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import Metal
import simd

func histogram(cellRadius: Float, distances: UnsafeMutablePointer<Float>, bins: Int, histogramArray: inout [Float]){
    
    //var histogramArrayCopy = histogramArray
    let binWidth: Float = 1.05/Float(bins)
    
    for i in 0..<524288{
        //let index: Int = Int(floor((distances[i] - 0)/Float(binWidth)))
        //histogramArray[index] += 1
        
        if distances[i] >= 0 && distances[i]/cellRadius < 1{
            let index: Int = Int(floor((distances[i]/cellRadius - 0)/Float(binWidth)))
            histogramArray[index] += 1
        }
    }
        
    /*for i in 0..<bins{
        histogram[i] = Float.random(in: 0...1)
    }*/
    
    //print(histogram)
    //return histogramArrayCopy
}
