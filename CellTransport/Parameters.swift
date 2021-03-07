//
//  Parameters.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/9/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

// MARK: - Parameters

/// Struct containing all parameters and constants used in the simulation
struct Parameters {

    /* CONSTANTS */
    static let KINESIN_ONLY: Int32 = 0 // Kinesin molecular motors for MTs (outward)
    static let DYNEIN_ONLY: Int32 = 1 // Dynein molecular motors for MTs (inward)
    
    static let REINJECT_INSIDE: Int32 = 0 // Reinject in the centrosome
    static let REINJECT_OUTSIDE: Int32 = 1 // Reinject in the cell membrane
    static let CONTAIN_INSIDE: Int32 = 2 // Contain organelles inside the cell
    
    static let SPHERICAL_CELL: Int32 = 0 // Spherical cell
    static let ORTHOGONAL_CELL: Int32 = 1 // Orthogonal cell

    static let RADIAL_MTS: Int32 = 0 // Radial microtubules
    static let APICAL_BASAL_MTS: Int32 = 1 // Apical-basal microtubules
    
    /* FIXED PARAMETERS */
    static var nCells: Int = 20 // Number of biological cells to simulate simultaneously
    static let cellsPerDimension = 100 // Cells are divided in cubic cells: cellsPerDimension for each side
    static var nbodies: Int = 40000 // 400 // 524288 // 4194304 //  16777216
    static let nMicrotubules: Int = 200 // 400
    static let centrosomeRadius: Float = 1200 // nm
    static let centrosomeLocation: SCNVector3 = SCNVector3(0.0, 0.0, 0.0) // nm
    static let nucleusRadius: Float = 5000 // nm
    static let nucleusLocation: SCNVector3 = SCNVector3(6500, 0.0, 0.0) // nm
    static let microtubuleSpeed: Float = 800 // nm/s
    static let microtubuleSegmentLength: Float = 50 // nm
    static let localAngle: Float = 0.05 // 0.15 // 0.05 // 0.015 // Radians
    static let maxLocalAngle: Float = 1*localAngle // Radians
    static let maxNSegments = 3200 // 200
    static var nucleusEnabled: Bool = false // Wether to generate a nucleus or not
    static let nonFreeMTdistance: Float = 2000 // nm
    static let bendMTs: Bool = false // Wether to bend MTs near the cell wall or nucleus

    /* CELL GEOMETRY */
    static var cellShape: Int32 = ORTHOGONAL_CELL // Cell shape
    static let cellRadius: Float = 12000 // nm, used only for SPHERICAL_CELL
    static let cellWidth: Float = 12000 // nm, used only for ORTHOGONAL_CELL
    static let cellHeight: Float = 24000 // nm, used only for ORTHOGONAL_CELL
    static let cellLength: Float = 12000 // nm, used only for ORTHOGONAL_CELL
    static let microtubulePreferredDirection = APICAL_BASAL_MTS // Microtubule structure preferred direction
    
    /* VARIABLE PARAMETERS */
    static var boundaryConditions: Int32 = CONTAIN_INSIDE // Molecular motor choice and boundary conditions
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

/// Struct containing parameters that will be used in the simulation after a restart but are not yet in use
class NotSetParameters: ObservableObject {

    static let shared = NotSetParameters()
    private init() {}

    @Published var needsRestart: Bool = false

    @Published var nCells = String(Parameters.nCells)
    @Published var nbodies = String(Parameters.nbodies)
    @Published var nucleusEnabled = String(Parameters.nucleusEnabled)
    @Published var cellShape = String(Parameters.cellShape)

    @Published var wON = String(Parameters.wON)
    @Published var wOFF = String(Parameters.wOFF)
}

// MARK: - Functions

/// Wether or not a restart is required to apply all parameters to the simulation
/// - Returns: `true` if a restart is required, `false` otherwise
public func checkForGlobalRestartCheck() {
    let notSetParameters = NotSetParameters.shared

    if notSetParameters.nCells != String(Parameters.nCells) {
        notSetParameters.needsRestart = true
        return
    } else if notSetParameters.nbodies != String(Parameters.nbodies) {
        notSetParameters.needsRestart = true
        return
    } else if notSetParameters.nucleusEnabled != String(Parameters.nucleusEnabled) {
        notSetParameters.needsRestart = true
        return
    } else if notSetParameters.cellShape != String(Parameters.cellShape) {
        notSetParameters.needsRestart = true
        return
    }
    // All checks passed, no restart required
    notSetParameters.needsRestart = false
}

/// Copy the parameters from the NotSetParameters struct to the Parameters struct used in the simulation
public func applyNewParameters() {
    // FIXME
    /*if let nCells = Int(NotSetParameters.nCells) {
        Parameters.nCells = nCells
    }
    if let nbodies = Int(NotSetParameters.nbodies) {
        Parameters.nbodies = nbodies
    }
    if let nucleusEnabled = Bool(NotSetParameters.nucleusEnabled) {
        Parameters.nucleusEnabled = nucleusEnabled
    }
    if let cellShape = Int32(NotSetParameters.cellShape) {
        Parameters.cellShape = cellShape
    }
    // Make all values nil again
    NotSetParameters.nCells = String(Parameters.nCells)
    NotSetParameters.nbodies = String(Parameters.nbodies)*/
}

/// Computes the timestep used in the simulation (deltat) based on microtubule segment length and speed.
///
/// The compute funcion moves an organelle from one point in the microtubule to the next point every `stepsPerMTPoint`
/// steps, effectively setting the simulation timestep.
public func computeDeltaT() {
    Parameters.deltat = Parameters.microtubuleSegmentLength / Parameters.microtubuleSpeed
}

// MARK: - Setters
// Setter closures return true if a restart is required to apply the changes, false if a
// restart is not required.

// Dynamic setters: values can be changed on-the-fly

let setWON: (String) -> Bool = { wON in
    // Check that wON can be converted to a valid float
    guard let wON = Float(wON) else {
        return false
    }

    // Check that the value is greater than 0
    guard wON >= 0 else {
        return false
    }

    // Check for numerical stability
    guard isNumericallyStable(wON: wON) else { return false }

    // Save the value and return on BOTH Parameters and NotSetParameters
    Parameters.wON = wON
    let notSetParameters = NotSetParameters.shared
    notSetParameters.wON = String(wON)
    return false
}

let setWOFF: (String) -> Bool = { wOFF in
    // Check that wOFF can be converted to a valid float
    guard let wOFF = Float(wOFF) else {
        return false
    }

    // Check that the value is greater than 0
    guard wOFF >= 0 else {
        return false
    }

    // Save the value and return
    Parameters.wOFF = wOFF
    return false
}

let setViscosity: (String) -> Bool = { viscosity in
    // Check that viscosity can be converted to a valid float
    guard let viscosity = Float(viscosity) else {
        return false
    }

    // Save the value and return
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

/*let toggleNucleus: (String) -> Bool = { state in
    if state == "true" {
        NotSetParameters.nucleusEnabled = "true"
        if NotSetParameters.nucleusEnabled == String(Parameters.nucleusEnabled) {
            return false
        } else {
            return true
        }
    } else if state == "false" {
        NotSetParameters.nucleusEnabled = "false"
        if NotSetParameters.nucleusEnabled == String(Parameters.nucleusEnabled) {
            return false
        } else {
            return true
        }
    } else {
        NSLog("Invalid value passed to toggleCollisions")
        return false
    }
}*/

// Other setters: require restart

let setNCells: (String) -> Bool = { nCells in
    // Check that viscosity can be converted to a valid int
    guard let nCells = Int(nCells) else {
        return false
    }
    let notSetParameters = NotSetParameters.shared
    notSetParameters.nCells = String(nCells)
    // A restart is required unless the simulation is already using the target value
    if String(nCells) == String(Parameters.nCells) {
        return false
    } else {
        return true
    }
}

/*let setNBodies: (String) -> Bool = { nbodies in
    // Check that viscosity can be converted to a valid int
    guard let nbodies = Int(nbodies) else {
        return false
    }
    NotSetParameters.nbodies = String(nbodies)
    // A restart is required unless the simulation is already using the target value
    if String(nbodies) == String(Parameters.nbodies) {
        return false
    } else {
        return true
    }
}*/

let setMolecularMotors: (String) -> Bool = { molecularMotor in
    // Check that viscosity can be converted to a valid int
    guard let molecularMotor = Int32(molecularMotor) else {
        return false
    }
    switch molecularMotor {
    case Parameters.KINESIN_ONLY:
        Parameters.molecularMotors = Parameters.KINESIN_ONLY
    case Parameters.DYNEIN_ONLY:
        Parameters.molecularMotors = Parameters.DYNEIN_ONLY
    default:
        // Don't change anything otherwise
        return false
    }
    return false
}

let setBoundaryConditions: (String) -> Bool = { boundaryConditions in
    // Check that viscosity can be converted to a valid int
    guard let boundaryConditions = Int32(boundaryConditions) else {
        return false
    }
    switch boundaryConditions {
    case Parameters.REINJECT_INSIDE:
        Parameters.boundaryConditions = Parameters.REINJECT_INSIDE
    case Parameters.REINJECT_OUTSIDE:
        Parameters.boundaryConditions = Parameters.REINJECT_OUTSIDE
    case Parameters.CONTAIN_INSIDE:
        Parameters.boundaryConditions = Parameters.CONTAIN_INSIDE
    default:
        // Don't change anything otherwise
        return false
    }
    return false
}

/*let setCellShape: (String) -> Bool = { cellShape in
    // Check that viscosity can be converted to a valid int
    guard let cellShape = Int32(cellShape) else {
        return false
    }
    switch cellShape {
    case Parameters.SPHERICAL_CELL:
        NotSetParameters.cellShape = String(Parameters.SPHERICAL_CELL)
    case Parameters.ORTHOGONAL_CELL:
        NotSetParameters.cellShape = String(Parameters.ORTHOGONAL_CELL)
    default:
        // Don't change anything otherwise
        return false
    }
    if String(Parameters.cellShape) == NotSetParameters.cellShape {
        return false
    } else {
        return true
    }
}*/

// MARK: - Getters
/// Some UI functions use this getters since they have to process the value to retrieve a useful string

let getMolecularMotors: () -> String = {
    switch Parameters.molecularMotors {
    case Parameters.KINESIN_ONLY:
        return "0"
    case Parameters.DYNEIN_ONLY:
        return "1"
    default:
        return "Error"
    }
}

let getBoundaryConditions: () -> String = {
    switch Parameters.boundaryConditions {
    case Parameters.REINJECT_INSIDE:
        return String(Parameters.REINJECT_INSIDE)
    case Parameters.REINJECT_OUTSIDE:
        return String(Parameters.REINJECT_OUTSIDE)
    case Parameters.CONTAIN_INSIDE:
        return String(Parameters.CONTAIN_INSIDE)
    default:
        return "Error"
    }
}

let getCellShape: () -> String = {
    switch Parameters.cellShape {
    case Parameters.SPHERICAL_CELL:
        return String(Parameters.SPHERICAL_CELL)
    case Parameters.ORTHOGONAL_CELL:
        return String(Parameters.ORTHOGONAL_CELL)
    default:
        return "Error"
    }
}

let getWON: () -> String = {
    let notSetParameters = NotSetParameters.shared
    return notSetParameters.wON
}

let getWOFF: () -> String = {
    let notSetParameters = NotSetParameters.shared
    return notSetParameters.wOFF
}

let getNCells: () -> String = {
    let notSetParameters = NotSetParameters.shared
    return notSetParameters.nCells
}
