//
//  SpawnMicrotubuleStructure.swift
//  
//
//  Created by Raúl Montón Pinillos on 20/2/21.
//

import Foundation
import SceneKit

func spawnAllMicrotubules(alertLabel: UILabel?,
                          scene: SCNScene?,
                          computeTabViewController: ComputeViewController?,
                          microtubulePointsArray: inout [simd_float3],
                          cellIDDict: inout [Int: [Int]],
                          cellIDtoIndex: inout [Int32],
                          cellIDtoNMTs: inout [Int16],
                          indexToPoint: inout [Int32]) -> ([SCNNode], [SCNVector3], [Int], [simd_float3]) {

    // Track progress of cells with completed MTs
    var completedMTsCount: Int = Parameters.nMicrotubules // First cell is not computed in parallel, excluded from progress count
    var progressFinishedUpdating = true
    let startTime = NSDate.now

    func updateProgress() {
        let fractionCompleted = Float(completedMTsCount)/Float(Parameters.nMicrotubules*Parameters.nCells)
        DispatchQueue.main.async {
            alertLabel?.text = "Generating microtubule structure of remaining cells: "
                                    + String(format: "%.2f", 100*fractionCompleted)
                                    + "% ("
                                    + formatRemainingTime(startTime: startTime, progress: fractionCompleted)
                                    + ")"
            progressFinishedUpdating = true
        }
    }

    // Create all-cells arrays
    var nodelist: [SCNNode] = []
    var microtubulePoints: [SCNVector3] = []
    var microtubuleNSegments: [Int] = []
    var separateMicrotubulePoints: [[simd_float3]] = []

    var cellsPointsNumber: [Int] = []

    // Add initial separator
    microtubulePointsArray.append(simd_float3(Parameters.cellRadius, Parameters.cellRadius, Parameters.cellRadius))

    // Generate MTs for the first cell

    DispatchQueue.main.async {
        alertLabel?.text = "Generating microtubule structure of the first cell"
    }

    var cellPoints: Int = 0

    for _ in 0..<Parameters.nMicrotubules {
        let points = generateMicrotubule(cellRadius: Parameters.cellRadius,
                                         centrosomeRadius: Parameters.centrosomeRadius,
                                         centrosomeLocation: Parameters.centrosomeLocation,
                                         nucleusRadius: Parameters.nucleusRadius,
                                         nucleusLocation: Parameters.nucleusLocation)
        microtubuleNSegments.append(points.count)

        for point in points {
            microtubulePoints.append(point)
            microtubulePointsArray.append(simd_float3(point))
        }

        // Introduce separators after each MT (situated at an impossible point)
        microtubulePointsArray.append(simd_float3(Parameters.cellRadius, Parameters.cellRadius, Parameters.cellRadius))

        // Update the number of MT points in the cell (including separator, +1)
        cellPoints += points.count + 1

        // UI configuration for the first cell (the only cell displayed on screen)

        let microtubuleColor = UIColor.green.withAlphaComponent(0.0).cgColor
        let geometry = SCNGeometry.lineThrough(points: points,
                                               width: 2,
                                               closed: false,
                                               color: microtubuleColor)
        let node = SCNNode(geometry: geometry)
        scene?.rootNode.addChildNode(node)
        nodelist.append(node)
    }

    // Update the length of each cell's MT points
    cellsPointsNumber.append(cellPoints)

    // Create a thread safe queue to write to all-cells arrays
    let threadSafeQueueForArrays = DispatchQueue(label: "Thread-safe write to arrays")
    let progressUpdateQueue = DispatchQueue(label: "Progress update queue")

    // Generate MTs for each cell concurrently (will use max available cores)
    DispatchQueue.concurrentPerform(iterations: Parameters.nCells - 1, execute: { _ in

        var cellPoints: Int = 0

        var localMicrotubulePoints: [SCNVector3] = []
        var localMicrotubuleNSegments: [Int] = []
        var localMicrotubulePointsArray: [simd_float3] = []
        var localSeparateMicrotubulePointsArray: [[simd_float3]] = []

        for _ in 0..<Parameters.nMicrotubules {
            var localMicrotubule: [simd_float3] = []
            let points = generateMicrotubule(cellRadius: Parameters.cellRadius,
                                             centrosomeRadius: Parameters.centrosomeRadius,
                                             centrosomeLocation: Parameters.centrosomeLocation,
                                             nucleusRadius: Parameters.nucleusRadius,
                                             nucleusLocation: Parameters.nucleusLocation)

            localMicrotubuleNSegments.append(points.count)

            for point in points {
                localMicrotubule.append(simd_float3(point))
                localMicrotubulePoints.append(point)
                localMicrotubulePointsArray.append(simd_float3(point))
            }

            // Introduce separators after each MT (situated at an impossible point)
            localMicrotubulePointsArray.append(simd_float3(Parameters.cellRadius, Parameters.cellRadius, Parameters.cellRadius))

            // Update the number of MT points in the cell (including separator, +1)
            cellPoints += points.count + 1

            // Mark the microtubule as completed and show progress
            progressUpdateQueue.async {
                completedMTsCount += 1
                if progressFinishedUpdating {
                    updateProgress()
                }
            }
            // Append microtubule
            localSeparateMicrotubulePointsArray.append(localMicrotubule)
        }

        // Update all-cells array with local ones safely
        threadSafeQueueForArrays.sync {

            microtubulePoints.append(contentsOf: localMicrotubulePoints)
            microtubuleNSegments.append(contentsOf: localMicrotubuleNSegments)
            microtubulePointsArray.append(contentsOf: localMicrotubulePointsArray)

            // Update the length of each cell's MT points
            cellsPointsNumber.append(cellPoints)
            separateMicrotubulePoints.append(contentsOf: localSeparateMicrotubulePointsArray)

        }
    })

    computeTabViewController?.MTcollection = separateMicrotubulePoints

    DispatchQueue.main.async {
        alertLabel?.text = "Generating microtubule structure: Converting arrays for Metal"
    }

    // Add MTs to the CellID dictionary

    addMTToCellIDDict(cellIDDict: &cellIDDict,
                      points: microtubulePointsArray,
                      cellNMTPoints: cellsPointsNumber,
                      cellRadius: Parameters.cellRadius,
                      cellsPerDimension: Parameters.cellsPerDimension)

    // Convert MT dictionary to arrays

    cellIDDictToArrays(cellIDDict: cellIDDict,
                       cellIDtoIndex: &cellIDtoIndex,
                       cellIDtoNMTs: &cellIDtoNMTs,
                       MTIndexArray: &indexToPoint,
                       nCells: Parameters.nCells,
                       cellsPerDimension: Parameters.cellsPerDimension,
                       alertLabel: alertLabel)

    return (nodelist, microtubulePoints, microtubuleNSegments, microtubulePointsArray)
}
