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

func getCellID(x: Float, y: Float, z: Float, cellRadius: Float, cellsPerDimension: Int) -> Int{
    
    var cellID: Int = 0
    let cellsPerDimensionSquared: Int = cellsPerDimension*cellsPerDimension
    
    //Break the computation into smaller ones so the Swift compiler doesn't complain
    let stupidComputation1: Float = (Float(cellsPerDimension) * ((z+cellRadius/2)/(2*cellRadius)))
    let stupidComputation2: Float = (Float(cellsPerDimension) * ((y+cellRadius/2)/(2*cellRadius)))
    let stupidCOmputation3: Float = (Float(cellsPerDimension) * ((x+cellRadius/2)/(2*cellRadius)))
    
    let floor1: Int = Int(floor(stupidComputation1))
    let floor2: Int = Int(floor(stupidComputation2))
    let floor3: Int = Int(floor(stupidCOmputation3))
        
    cellID += cellsPerDimensionSquared * floor1
    cellID += cellsPerDimension * floor2
    cellID += floor3
    
    return cellID
}

func addMTToCellIDDict(cellIDDict: inout Dictionary<Int, [Int]>, points: [simd_float3], cellNMTPoints: [Int], cellRadius: Float, cellsPerDimension: Int){
    
    let maxNumberOfCells = cellsPerDimension*cellsPerDimension*cellsPerDimension
    var counter: Int = 0
    var cellNCounter: Int = 0
    
    for NmicrotubulesInCell in cellNMTPoints{
        for i in 0..<NmicrotubulesInCell{
            //Retrieve the current MT point
            let currentPoint = points[i+counter]
            
            //Find the associated CellID
            var currentCellID = getCellID(x: currentPoint.x, y: currentPoint.y, z: currentPoint.z, cellRadius: cellRadius, cellsPerDimension: cellsPerDimension)
            currentCellID += maxNumberOfCells*cellNCounter
            
            //Check if CellID is already on dictionary
            if cellIDDict[currentCellID] != nil{
                cellIDDict[currentCellID]!.append(i+counter)
            }else{
                cellIDDict[currentCellID] = [i+counter]
            }
        }
        counter += NmicrotubulesInCell
        cellNCounter += 1
    }
}
