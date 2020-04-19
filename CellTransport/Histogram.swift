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
import SceneKit

func histogram(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nDistances: Int, bins: Int, histogramArray: inout [Float]){
    
    let binWidth: Float = 1.0/Float(bins)
    
    for i in 0..<nDistances{
        if distances[i] >= 0 && distances[i]/cellRadius < 1{
            let index: Int = Int(floor((distances[i]/cellRadius)/Float(binWidth)))
            histogramArray[index] += 1
        }
    }
}

func histogramLengths(lengths: [Int], histogramArray: inout [Float]){
            
    for length in lengths{
        let index: Int = length - 1
        histogramArray[index] += 1
    }
}

func histogramMT(cellRadius: Float, points: [SCNVector3], bins: Int, histogramArray: inout [Float]){
    
    let binWidth: Float = 1.0/Float(bins)
    
    for i in 0..<(points.count - 1){
        
        // Check if next point is from the same microtubule (it should then be at a distance equal to the segmentLenght, within a small tolerance)
        if abs(simd_distance(simd_float3(points[i]), simd_float3(points[i+1])) - 200.0) < 0.1{
            
            let newPoints: [simd_float3] = stride(from: 0.0, to: 1.0, by: 1 / 100).map { x in
                return mix(simd_float3(points[i]), simd_float3(points[i+1]), t: x)
            }
            
            for point in newPoints{
                let distance = simd_length(point)
                
                if distance/cellRadius < 1{
                    let index: Int = Int(floor((distance/cellRadius - 0)/Float(binWidth)))
                    histogramArray[index] += 1
                }
            }
            
        }
    }
}

func densify(cellRadius: Float, bins: Int, histogramArray: inout [Float]){
        
    let binRadiusSegment = cellRadius / Float(bins)
    histogramArray[0] = histogramArray[0] / (4.0/3.0*Float.pi * powf(binRadiusSegment, 3))
    for i in 1..<histogramArray.count{
        let outerVolume = 4.0/3.0*Float.pi * powf(binRadiusSegment*Float((i+1)), 3)
        let innerVolume = 4.0/3.0*Float.pi * powf(binRadiusSegment*Float(i), 3)
        histogramArray[i] = histogramArray[i]/(outerVolume - innerVolume)
    }
}
