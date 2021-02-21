//
//  HelperFunctions.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 30/06/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import simd
import SceneKit
import UIKit

func setBenchmarkLabel(benchmarkLabel: UILabel, startTime: Date, steps: Int) {
    
    let elapsedTime = -Double(startTime.timeIntervalSinceNow)
    
    DispatchQueue.main.async {
        benchmarkLabel.text = String(round(Double(steps)/elapsedTime)) + " steps/second"
    }
}

func formatRemainingTime(startTime: Date, progress: Float) -> String {
    /**
     Obtain a formatted String with the remaining time from a computationally expensive operation.
     - Parameters:
       - startTime: The time the operation started.
       - progress: The progress achieved so far (ranges 0 to 1).
     - Returns: Formatted String showing remaining days, hours and minutes (up to two of them).
     */
    
    let remainingTime = (-Double(startTime.timeIntervalSinceNow) / Double(progress)) * (1 - Double(progress))
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.maximumUnitCount = 2
    if remainingTime.isFinite {
        return formatter.string(from: remainingTime)!
    } else {
        return "Unknown"
    }
}

func average(_ input: [Double]) -> Double {
    return input.reduce(0, +) / Double(input.count)
}
func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
    return zip(a, b).map(*)
}

func linearRegression(_ xData: [Double], _ yData: [Double]) -> (Double) {
    let sum1 = average(multiply(yData, xData)) - average(xData) * average(yData)
    let sum2 = average(multiply(xData, xData)) - pow(average(xData), 2)
    let slope = sum1 / sum2
    // let intercept = average(yData) - slope * average(xData)
    return slope
}

func expectedValueCosine(points: [simd_float3], bins: Int) -> ([Float], [Int]) {
    
    let maxDistance: Float = Float(Parameters.maxNSegments) * Parameters.microtubuleSegmentLength
    var expectedValueCosineArray = [Float](repeating: 0, count: bins)
    var expectedValueCount = [Int](repeating: 0, count: bins)
    
    for i in 0..<points.count {
        let pointDistance = Parameters.microtubuleSegmentLength*Float(i)
        let cosine = dot( normalize(points[0]), normalize(points[i]) )
        let index: Int = Int(floor( Float(bins) * (pointDistance/maxDistance) ))
        expectedValueCosineArray[index] += cosine
        expectedValueCount[index] += 1
    }
    
    return (expectedValueCosineArray, expectedValueCount)
}

func getCellID(x: Float, y: Float, z: Float, cellRadius: Float, cellsPerDimension: Int) -> Int {
    
    var cellID: Int = 0
    let cellsPerDimensionSquared: Int = cellsPerDimension*cellsPerDimension
    
    // Break the computation into smaller ones so the Swift compiler doesn't complain
    let stupidComputation1: Float = (Float(cellsPerDimension) * ((z+cellRadius)/(2*cellRadius)))
    let stupidComputation2: Float = (Float(cellsPerDimension) * ((y+cellRadius)/(2*cellRadius)))
    let stupidCOmputation3: Float = (Float(cellsPerDimension) * ((x+cellRadius)/(2*cellRadius)))
    
    let floor1: Int = Int(floor(stupidComputation1))
    let floor2: Int = Int(floor(stupidComputation2))
    let floor3: Int = Int(floor(stupidCOmputation3))
        
    cellID += cellsPerDimensionSquared * floor1
    cellID += cellsPerDimension * floor2
    cellID += floor3
    
    return cellID
}

func addMTToCellIDDict(cellIDDict: inout [Int: [Int]], points: [simd_float3], cellNMTPoints: [Int], cellRadius: Float, cellsPerDimension: Int) {
    
    let maxNumberOfCells = cellsPerDimension*cellsPerDimension*cellsPerDimension
    var counter: Int = 0
    var cellNCounter: Int = 0
    
    for NmicrotubulesInCell in cellNMTPoints {
        for i in 0..<NmicrotubulesInCell {
            // Retrieve the current MT point
            let currentPoint = points[i+counter]
            
            // Find the associated CellID
            var currentCellID = getCellID(x: currentPoint.x,
                                          y: currentPoint.y,
                                          z: currentPoint.z,
                                          cellRadius: cellRadius,
                                          cellsPerDimension: cellsPerDimension)
            currentCellID += maxNumberOfCells*cellNCounter
 
            // Check if CellID is already on dictionary
            if cellIDDict[currentCellID] != nil {
                cellIDDict[currentCellID]!.append(i+counter)
            } else {
                cellIDDict[currentCellID] = [i+counter]
            }
        }
        counter += NmicrotubulesInCell
        cellNCounter += 1
    }
}

func cellIDDictToArrays(cellIDDict: [Int: [Int]], cellIDtoIndex: inout [Int32], cellIDtoNMTs: inout [Int16], MTIndexArray: inout [Int32], nCells: Int, cellsPerDimension: Int, alertLabel: UILabel?) {
    
    let progressUpdateQueue = DispatchQueue(label: "Progress update queue")
    var progressFinishedUpdating = true
    let startTime = NSDate.now
    
    func updateProgress(cellNumber: Int) {
        let fractionCompleted = Float(cellNumber)/Float(Parameters.nCells)
        DispatchQueue.main.async {
            alertLabel?.text = "Converting arrays for metal: "
                                    + String(format: "%.2f", 100*fractionCompleted)
                                    + "% ("
                                    + formatRemainingTime(startTime: startTime, progress: fractionCompleted)
                                    + ")"
            progressFinishedUpdating = true
        }
    }
    
    let maxNumberOfCells = cellsPerDimension*cellsPerDimension*cellsPerDimension
    var currentMTindex: Int = 0
    
    cellIDtoIndex = [Int32](repeating: -1, count: maxNumberOfCells*Parameters.nCells)
    cellIDtoNMTs = [Int16](repeating: 0, count: maxNumberOfCells*Parameters.nCells)
    
    for i in 0..<nCells {
        for j in 0..<maxNumberOfCells {
            let cellID = i*maxNumberOfCells + j
            
            if cellIDDict[cellID] != nil {
                // Count the numbers of MTs in that specific cell and add that to the array
                cellIDtoNMTs[cellID] = Int16(cellIDDict[cellID]!.count)
                                
                // Add the index of the FIRST MT in that specific cell to the cellIDtoIndex array
                cellIDtoIndex[cellID] = Int32(currentMTindex)
                
                // Add all MTs indexes to the MTindexArray
                for MTindex in cellIDDict[cellID]! {
                    MTIndexArray.append(Int32(MTindex))
                }
                
                // Move the current MTindex
                currentMTindex += cellIDDict[cellID]!.count
            }
            
        }
        
        // Update progress converting dictionaries to metal
        progressUpdateQueue.async {
            if progressFinishedUpdating {
                updateProgress(cellNumber: i)
            }
        }
        
    }
}
