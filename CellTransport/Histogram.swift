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
    let binWidth: Float = 1.0/Float(bins)
    
    for i in 0..<131072{
        //let index: Int = Int(floor((distances[i] - 0)/Float(binWidth)))
        //histogramArray[index] += 1
        
        if distances[i] >= 0 && distances[i]/cellRadius < 1{
            let index: Int = Int(floor((distances[i]/cellRadius - 0)/Float(binWidth)))
            histogramArray[index] += 1
        }
    }

}

func histogram(cellRadius: Float, distances: [Float], bins: Int, histogramArray: inout [Float]){
    
    //var histogramArrayCopy = histogramArray
    let binWidth: Float = 1.0/Float(bins)
    
    for i in 0..<distances.count{
        //let index: Int = Int(floor((distances[i] - 0)/Float(binWidth)))
        //histogramArray[index] += 1
        
        if distances[i] >= 0 && distances[i]/cellRadius < 1{
            let index: Int = Int(floor((distances[i]/cellRadius - 0)/Float(binWidth)))
            histogramArray[index] += 1
        }
    }
    
    let binRadiusSegment = cellRadius / Float(bins)
    histogramArray[0] /= 4.0/3.0*Float.pi * powf(binRadiusSegment, 3)
    for i in 1..<histogramArray.count{
        let outerVolume = 4.0/3.0*Float.pi * powf(binRadiusSegment*Float((i+1)), 3)
        let innerVolume = 4.0/3.0*Float.pi * powf(binRadiusSegment*Float(i), 3)
        histogramArray[i] /= outerVolume - innerVolume
    }

}
