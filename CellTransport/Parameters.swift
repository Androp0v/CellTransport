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
    static let nucleusLocation: SCNVector3 = SCNVector3(0.0,0.0,0.2*14000) //nm
    static let centrosomeLocation: SCNVector3 = SCNVector3(0.0,0.0,0.0) //nm
    static let microtubuleSpeed: Float = 800 //nm/s
    static let microtubuleSegmentLength: Float = 50 //nm
    static let localAngle: Float = 0.015 //0.15 //Radians
    static let maxLocalAngle: Float = 2*localAngle //Radians
    static let maxNSegments = 800 //200
    
    /* VARIABLE PARAMETERS */
    static var collisionsFlag = false //Enables or disables collisions
    static var deltat: Float = 0.0 //Timestep
    static var wON: Float = 3.5 //Probability of attachment
    static var wOFF: Float = 1.0 //Probability of dettachment
    static var n_w: Float = 10 //Viscosity in water viscosity units
}

public func computeDeltaT() {
    // Computes deltat based on microtubule segment lenght and speed
    parameters.deltat = parameters.microtubuleSegmentLength/parameters.microtubuleSpeed
}
