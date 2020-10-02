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
    
    /* CONSTANTS */
    static let KINESIN_ONLY: Int32 = 0 //Kinesin molecular motors for MTs (outward)
    static let DYNEIN_ONLY: Int32 = 1 //Dynein molecular motors for MTs (inward)
    
    /* FIXED PARAMETERS */
    static let nCells: Int = 20 //Number of biological cells to simulate simultaneously
    static let cellsPerDimension = 100 //Cells are divided in cubic cells: cellsPerDimension for each side
    static let nbodies: Int = 40000 //524288 //4194304 // 16777216
    static let nMicrotubules: Int = 200 //400
    static let cellRadius: Float = 12000 //nm
    static let centrosomeRadius: Float = 1200 //nm
    static let nucleusLocation: SCNVector3 = SCNVector3(0.0,0.0,0.2*14000) //nm
    static let centrosomeLocation: SCNVector3 = SCNVector3(0.0,0.0,0.0) //nm
    static let microtubuleSpeed: Float = 800 //nm/s
    static let microtubuleSegmentLength: Float = 50 //nm
    static let localAngle: Float = 0.05 //0.015 //Radians
    static let maxLocalAngle: Float = 2*localAngle //Radians
    static let maxNSegments = 800 //200
    
    /* VARIABLE PARAMETERS */
    static var boundaryConditions: Int32 = KINESIN_ONLY //Molecular motor choice and boundary conditions
    static var collisionsFlag: Bool = false //Enables or disables collisions
    static var deltat: Float = 0.0 //Timestep. Fixed by microtubule speed.
    static var wON: Float = 99385000 //3.5 //Probability of attachment, nm^3/s
    static var wOFF: Float = 1.0 //Probability of dettachment
    static var n_w: Float = 10 //Viscosity in water viscosity units
}

public func computeDeltaT() {
    // Computes deltat based on microtubule segment lenght and speed
    parameters.deltat = parameters.microtubuleSegmentLength/parameters.microtubuleSpeed
}
