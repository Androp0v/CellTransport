//
//  IOFunctions.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/03/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation

func exportHistogramToFile(histogram: [Float], folderURL: URL, filename: String) {
        
    var exportURL = folderURL
    exportURL.appendPathComponent(filename + String(".txt"))
    
    // Convert array of floats to array of Strings
    let numberFormat = NumberFormatter()
    numberFormat.numberStyle = .scientific
    let histogramStringArray = histogram.map{numberFormat.string(from: NSNumber(value: $0))!}
    
    // Merge into a single string, separated by \n
    let histogramString = histogramStringArray.joined(separator: "\n")
    
    // Write to file (atomically!)
    do{
        try histogramString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}

func getMolecularMotorName(boundaryConditions: Int32) -> String {
    switch boundaryConditions {
    case parameters.KINESIN_ONLY:
        return "KINESIN_ONLY"
    case parameters.KINESIN_ONLY:
        return "DYNEIN_ONLY"
    default:
        return "DEFAULT_TO_KINESIN_ONLY"
    }
}

func exportParametersToFile(folderURL: URL, filename: String) {
    
    var exportURL = folderURL
    exportURL.appendPathComponent(filename + String(".txt"))
    
    // Create an empty string
    var parametersString: String = String()
    
    // Append parameters
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
    
    // Append variable parameters
    parametersString += "Molecular motors: " + getMolecularMotorName(boundaryConditions: parameters.boundaryConditions) + "\n"
    parametersString += "Collisions enabled: " + String(parameters.collisionsFlag) + "\n"
    parametersString += "Attachment probability: " + String(parameters.wON) + "nm^3*s^-1"
    parametersString += "Dettachment probability: " + String(parameters.wON) + "s^-1"
    parametersString += "Diffusion delta time: " + String(parameters.deltat) + " s\n"
    parametersString += "Cells per dimension: " + String(parameters.cellsPerDimension)
    
    // Write to file (atomically!)
    do{
        try parametersString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}
