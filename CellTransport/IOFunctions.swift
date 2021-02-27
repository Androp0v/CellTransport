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
    
    // Check that the histogram array is not empty
    if histogram.count > 0 {
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
    }
    
    // Write to file (atomically!)
    do {
        try histogramString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}

func getMolecularMotorName(molecularMotors: Int32) -> String {
    switch molecularMotors {
    case Parameters.KINESIN_ONLY:
        return "KINESIN_ONLY"
    case Parameters.KINESIN_ONLY:
        return "DYNEIN_ONLY"
    default:
        return "DEFAULT_TO_KINESIN_ONLY"
    }
}

func getBoundaryName(boundaryConditions: Int32) -> String {
    switch boundaryConditions {
    case Parameters.REINJECT_INSIDE:
        return "REINJECT_INSIDE"
    case Parameters.REINJECT_OUTSIDE:
        return "REINJECT_OUTSIDE"
    case Parameters.CONTAIN_INSIDE:
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
    parametersString += "Number of biological cells: " + String(Parameters.nCells) + "\n"
    parametersString += "Particles per cell: " + String(Parameters.nbodies/Parameters.nCells) + "\n"
    parametersString += "Microtubules per cell: " + String(Parameters.nMicrotubules) + "\n"
    parametersString += "Cell radius: " + String(Parameters.cellRadius) + " nm\n"
    parametersString += "Centrosome radius: " + String(Parameters.centrosomeRadius) + " nm\n"
    parametersString += "Microtubule speed: " + String(Parameters.microtubuleSpeed) + " nm/s\n"
    parametersString += "Microtubule segment length: " + String(Parameters.microtubuleSegmentLength) + " nm\n"
    parametersString += "Microtubule local angle: " + String(Parameters.localAngle) + " radians\n"
    parametersString += "Microtubule max local angle: " + String(Parameters.maxLocalAngle) + " radians\n"
    parametersString += "Microtubule max segments: " + String(Parameters.maxNSegments) + "\n"
    parametersString += "Nucleus enabled: " + String(Parameters.nucleusEnabled) + "\n"
    
    // Append variable parameters
    parametersString += "\nVARIABLE PARAMETERS\n"
    parametersString += "Molecular motors: " + getMolecularMotorName(molecularMotors: Parameters.molecularMotors) + "\n"
    parametersString += "Boundary conditions: " + getBoundaryName(boundaryConditions: Parameters.boundaryConditions) + "\n"
    parametersString += "Collisions enabled: " + String(Parameters.collisionsFlag) + "\n"
    parametersString += "Attachment probability: " + String(Parameters.wON) + " nm^3*s^-1\n"
    parametersString += "Detachment probability: " + String(Parameters.wOFF) + " s^-1\n"
    parametersString += "Timestep: " + String(Parameters.deltat / Float(Parameters.stepsPerMTPoint)) + " s\n"
    parametersString += "Cells per dimension: " + String(Parameters.cellsPerDimension) + "\n"
    parametersString += "Cytoplasm viscosity: " + String(Parameters.n_w) + " (water viscosity units)\n"
    
    // Write to file (atomically!)
    do {
        try parametersString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}
