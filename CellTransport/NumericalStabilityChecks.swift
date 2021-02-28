//
//  NumericalStabilityChecks.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import Foundation

// MARK: Linspace
public func linspace<T: FloatingPoint>(_ start: T, _ end: T, _ count: Int) -> [T] {
    let distance  = abs(end - start)
    let num = distance / T(count-1)
    var result: [T] = []
    var i: T = start
    while i <= end {
            result.append(i)
            i+=num
        }
    return result
}

// MARK: - Numerical checks

func isNumericallyStable(wON: Float) -> Bool {

    // Check for numerical stability: too high wON values may cause numerical stability
    // errors resulting in wrong behaviour. Check the stability of the inputted values:
    for wON in linspace(0, wON, 1000) {

        // 32-bits result (used on the GPU):
        let cellVolume_32bits: Float32 = pow(Float32(2) * Float32(Parameters.cellRadius) / Float32(Parameters.cellsPerDimension), Float32(3.0))
        let result_32bits = 1 - pow(1 - Float32(wON) * (Float32(Parameters.deltat)
                                                            / Float32(Parameters.stepsPerMTPoint)) / cellVolume_32bits,
                                    Float32(1))

        // 64-bits result (used for precision check):
        let cellVolume_64bits: Float64 = pow(2 * Float64(Parameters.cellRadius) / Float64(Parameters.cellsPerDimension), Float64(3.0))
        let result_64bits = 1 - pow(Float64(1 - Float64(wON) * (Float64(Parameters.deltat)
                                                            / Float64(Parameters.stepsPerMTPoint)) / cellVolume_64bits),
                                    Float64(1))

        // Precision checking
        guard result_32bits <= 1.0 else {
            NSLog("Tried to set a wON value that could result in probability of attachment greater than 1")
            return false
        }
        guard result_32bits >= 0.0 else {
            NSLog("Tried to set a wON value that could result in negative probability of attachment")
            return false
        }
        guard abs(result_64bits - Float64(result_32bits)) < 0.01 else {
            NSLog("Tried to set a wON value that could result in unacceptable numerical precision loss")
            return false
        }

    }

    // All tests passed, good to go!
    return true
}
