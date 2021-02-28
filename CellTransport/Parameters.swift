//
//  Parameters.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/9/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

/// Struct containing all parameters and constants used in the simulation
struct Parameters {
    
    /* CONSTANTS */
    static let KINESIN_ONLY: Int32 = 0 // Kinesin molecular motors for MTs (outward)
    static let DYNEIN_ONLY: Int32 = 1 // Dynein molecular motors for MTs (inward)
    
    static let REINJECT_INSIDE: Int32 = 0 // Reinject in the centrosome
    static let REINJECT_OUTSIDE: Int32 = 1 // Reinject in the cell membrane
    static let CONTAIN_INSIDE: Int32 = 2 // Contain organelles inside the cell
    
    static let SPHERICAL_CELL: Int32 = 0 // Spherical cell
    static let CUBIC_CELL: Int32 = 1 // Cubic cell
    
    /* FIXED PARAMETERS */
    static let nCells: Int = 2 // Number of biological cells to simulate simultaneously
    static let cellsPerDimension = 100 // Cells are divided in cubic cells: cellsPerDimension for each side
    static let nbodies: Int = 4000 // 400 // 524288 // 4194304 //  16777216
    static let nMicrotubules: Int = 200 // 400
    static let cellRadius: Float = 12000 // nm
    static let centrosomeRadius: Float = 1200 // nm
    static let centrosomeLocation: SCNVector3 = SCNVector3(0.0, 0.0, 0.0) // nm
    static let nucleusRadius: Float = 5000 // nm
    static let nucleusLocation: SCNVector3 = SCNVector3(6500, 0.0, 0.0) // nm
    static let microtubuleSpeed: Float = 800 // nm/s
    static let microtubuleSegmentLength: Float = 50 // nm
    static let localAngle: Float = 0.15 // 0.05 // 0.015 // Radians
    static let maxLocalAngle: Float = 1*localAngle // Radians
    static let maxNSegments = 3200 // 200
    static let nucleusEnabled: Bool = false // Wether to generate a nucleus or not, EXPERIMENTAL TO-DO
    static let nonFreeMTdistance: Float = 2000 // nm
    static let bendMTs: Bool = false // Wether to bend MTs near the cell wall or nucleus
    static let cellShape: Int32 = SPHERICAL_CELL // Cell shape
    
    /* VARIABLE PARAMETERS */
    static var boundaryConditions: Int32 = REINJECT_INSIDE // Molecular motor choice and boundary conditions
    static var molecularMotors: Int32 = KINESIN_ONLY // Molecular motor choice and boundary conditions
    static var collisionsFlag: Bool = false // Enables or disables collisions
    static var deltat: Float = 0.0 // Timestep. Fixed by microtubule speed
    static var stepsPerMTPoint: Int = 10 //  Subdivisions of each deltat timestep
    static var wON: Float = 33000000 // Probability of attachment, nm^3/s
    static var wOFF: Float = 1.0 // Probability of dettachment, s^-1
    static var n_w: Float = 10 // Viscosity in water viscosity units

    /* RUNNING SIMULATION STATS */
    static var time: Float = 0 // Simulation running time
    
    /* GRAPH PARAMETERS */
    
}

/// Struct containing parameters that will be used in the simulation after a restart
struct NotSetParameters {
    static var nCells: Int?
}

public func computeDeltaT() {
    // Computes deltat based on microtubule segment lenght and speed
    Parameters.deltat = Parameters.microtubuleSegmentLength / Parameters.microtubuleSpeed
}

// MARK: - Setters for user-requested changes
// Closures return true if a restart is required to apply the changes, false if a restart
// is not required.

// Dynamic setters: values can be changed on-the-fly

let setWON: (String) -> Bool = { wON in
    // Check that wON can be converted to a valid float
    guard let wON = Float(wON) else {
        return false
    }
    Parameters.wON = wON
    return false
}

let setWOFF: (String) -> Bool = { wOFF in
    // Check that wOFF can be converted to a valid float
    guard let wOFF = Float(wOFF) else {
        return false
    }
    Parameters.wOFF = wOFF
    return false
}

let setViscosity: (String) -> Bool = { viscosity in
    // Check that viscosity can be converted to a valid float
    guard let viscosity = Float(viscosity) else {
        return false
    }
    Parameters.n_w = viscosity
    return false
}

let toggleCollisions: (String) -> Bool = { state in
    if state == "true" {
        Parameters.collisionsFlag = true
        return false
    } else if state == "false" {
        Parameters.collisionsFlag = false
        return false
    } else {
        NSLog("Invalid value passed to toggleCollisions")
        return false
    }
}

// Other setters: require restart

let setNCells: (String) -> Bool = { nCells in
    // Check that viscosity can be converted to a valid int
    guard let nCells = Int(nCells) else {
        return false
    }
    NotSetParameters.nCells = nCells
    // A restart is required unless the simulation is already using the target value
    if nCells == Parameters.nCells {
        return false
    } else {
        return true
    }
}
