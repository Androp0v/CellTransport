//
//  IOFunctions.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/03/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation

func exportHistogramToFile(histogram: [[Float]], folderURL: URL, filename: String) {
    
    // Retrieve export path
    var exportURL = folderURL
    exportURL.appendPathComponent(filename + String(".txt"))
    
    // Configure number formatting
    let numberFormat = NumberFormatter() // Create a NumberFormatter to style output numbers
    numberFormat.numberStyle = .scientific // Scientific formatting (i.e. 1.8121E3)
    numberFormat.usesSignificantDigits = true // Use significant digits
    numberFormat.minimumSignificantDigits = 7 // Similar to significant digists of a Float32 type
    
    // Create a string to print to file
    var histogramString = String()
    
    // Loop over all positions and digits
    for i in 0..<histogram[0].count {
        for (column, columnData) in histogram.enumerated() {
            histogramString.append(numberFormat.string(from: NSNumber(value: columnData[i])) ?? "NaN")
            if column < histogram.count {
                histogramString.append("\t")
            }
        }
        if i < (histogram[0].count - 1) {
            histogramString.append("\n")
        }
    }
    
    // Write to file (atomically!)
    do{
        try histogramString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}

func getMolecularMotorName(molecularMotors: Int32) -> String {
    switch molecularMotors {
    case parameters.KINESIN_ONLY:
        return "KINESIN_ONLY"
    case parameters.KINESIN_ONLY:
        return "DYNEIN_ONLY"
    default:
        return "DEFAULT_TO_KINESIN_ONLY"
    }
}

func getBoundaryName(boundaryConditions: Int32) -> String {
    switch boundaryConditions {
    case parameters.REINJECT_INSIDE:
        return "REINJECT_INSIDE"
    case parameters.REINJECT_OUTSIDE:
        return "REINJECT_OUTSIDE"
    case parameters.CONTAIN_INSIDE:
        return "CONTAIN_INSIDE"
    default:
        return "DEFAULT_TO_REINJECT_INSIDE"
    }
}

func exportParametersToFile(folderURL: URL, filename: String) {
    
    var exportURL = folderURL
    exportURL.appendPathComponent(filename + String(".txt"))
    
    // Create an empty string
    var parametersString: String = String()
    
    // Append fixed parameters
    parametersString += "FIXED PARAMETERS\n"
    parametersString += "Number of biological cells: " + String(parameters.nCells) + "\n"
    parametersString += "Particles per cell: " + String(parameters.nbodies/parameters.nCells) + "\n"
    parametersString += "Microtubules per cell: " + String(parameters.nMicrotubules) + "\n"
    parametersString += "Cell radius: " + String(parameters.cellRadius) + " nm\n"
    parametersString += "Centrosome radius: " + String(parameters.centrosomeRadius) + " nm\n"
    parametersString += "Microtubule speed: " + String(parameters.microtubuleSpeed) + " nm/s\n"
    parametersString += "Microtubule segment length: " + String(parameters.microtubuleSegmentLength) + " nm\n"
    parametersString += "Microtubule local angle: " + String(parameters.localAngle) + " radians\n"
    parametersString += "Microtubule max local angle: " + String(parameters.maxLocalAngle) + " radians\n"
    parametersString += "Microtubule max segments: " + String(parameters.maxNSegments) + "\n"
    parametersString += "Nucleus enabled: " + String(parameters.nucleusEnabled) + "\n"
    
    // Append variable parameters
    parametersString += "\nVARIABLE PARAMETERS\n"
    parametersString += "Molecular motors: " + getMolecularMotorName(molecularMotors: parameters.molecularMotors) + "\n"
    parametersString += "Boundary conditions: " + getBoundaryName(boundaryConditions: parameters.boundaryConditions) + "\n"
    parametersString += "Collisions enabled: " + String(parameters.collisionsFlag) + "\n"
    parametersString += "Attachment probability: " + String(parameters.wON) + " nm^3*s^-1\n"
    parametersString += "Detachment probability: " + String(parameters.wON) + " s^-1\n"
    parametersString += "Timestep: " + String(parameters.deltat / Float(parameters.stepsPerMTPoint)) + " s\n"
    parametersString += "Cells per dimension: " + String(parameters.cellsPerDimension)
    
    // Write to file (atomically!)
    do{
        try parametersString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}
