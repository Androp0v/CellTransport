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

/*func getCellID(x: Float, y: Float, z: Float, cellRadius: Float, cellsPerDimension: Int) -> Int{
    
    var cellID: Int = 0
    let cellsPerDimensionSquared = pow(cellsPerDimension, 2)
    
    cellID += cellsPerDimensionSquared * floor(cellsPerDimension * ((z+cellRadius/2)/cellRadius))
    cellID += cellsPerDimension * floor(cellsPerDimension * ((y+cellRadius/2)/cellRadius))
    cellID += floor(cellsPerDimension * ((x+cellRadius/2)/cellRadius))
    
    return cellID
}*/

func addMTToCellIDDict(cellIDDict: Dictionary<Int, [Int]>, points: [SCNVector3], currentCellNumber: Int, cellsPerDimension: Int){
    
    
    
}
