//
//  Parameters.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/9/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

struct parameters {
    
    /* FIXED PARAMETERS */
    static let nCells: Int = 20 //Number of biological cells to simulate simultaneously
    static let cellsPerDimension = 100 //Cells are divided in cubic cells: cellsPerDimension for each side
    static let nbodies: Int = 40000 //524288 //4194304 // 16777216
    static let nMicrotubules: Int = 150 //400
    static let cellRadius: Float = 12000 //nm
    static let centrosomeRadius: Float = 1200 //nm
    static let nucleusLocation: SCNVector3 = SCNVector3(0.0,0.0,0.2*14000)
    static let centrosomeLocation: SCNVector3 = SCNVector3(0.0,0.0,0.0)
    static let microtubuleSpeed: Float = 800 //nm/s
    static let microtubuleSegmentLength: Float = 50 //nm
    
    /* VARIABLE PARAMETERS */
    static var collisionsFlag = false
    static var deltat: Float = 0.0
    static var wON: Float = 3.5
    static var wOFF: Float = 1.0
}

public func computeDeltaT() {
    // Computes deltat based on microtubule segment lenght and speed
    parameters.deltat = parameters.microtubuleSegmentLength/parameters.microtubuleSpeed
}
