//
//  SpawnMicrotubuleStructure.swift
//  
//
//  Created by Raúl Montón Pinillos on 20/2/21.
//

import Foundation
import SceneKit

/// Class to coordinate creating the structure of microtubules for all cells concurrently and update the UI
/// simultaneously. The implementation of the single microtubule generation itself is not part of this class,
/// as this class focuses
class MicrotubuleSpawner {

    // MARK: - Properties

    // UI elements
    private weak var alertLabel: UILabel?
    private weak var scene: SCNScene?
    private weak var computeTabViewController: ComputeViewController?

    // Control flow variables to handle progress update
    var completedMTsCount: Int?
    var progressFinishedUpdating: Bool?
    var startTime: Date?
    var progressUpdateQueue: DispatchQueue?

    // Create all-cells arrays
    var nodelist: [SCNNode] = []
    var microtubulePoints: [SCNVector3] = []
    var microtubuleNSegments: [Int] = []
    var separateMicrotubulePoints: [[simd_float3]] = []

    var cellsPointsNumber: [Int] = []

    // Thread safe queue to write to all-cells arrays
    var threadSafeQueueForArrays: DispatchQueue?

    init(alertLabel: UILabel?, scene: SCNScene?, computeTabViewController: ComputeViewController?) {
        self.alertLabel = alertLabel
        self.scene = scene
        self.computeTabViewController = computeTabViewController
    }

    // MARK: - UI updating functions

    private func updateProgress() {
        guard let completedMTsCount = self.completedMTsCount else { return }
        guard let startTime = self.startTime else { return }
        let fractionCompleted = Float(completedMTsCount) / Float(Parameters.nMicrotubules * Parameters.nCells)
        DispatchQueue.main.async {
            self.alertLabel?.text = "Generating microtubule structure of remaining cells: "
                                    + String(format: "%.2f", 100*fractionCompleted)
                                    + "% ("
                                    + formatRemainingTime(startTime: startTime, progress: fractionCompleted)
                                    + ")"
            self.progressFinishedUpdating = true
        }
    }

    // MARK: - Microtubule spawning

    func spawnAllMicrotubules(microtubulePointsArray: inout [simd_float3],
                              cellIDDict: inout [Int: [Int]],
                              cellIDtoIndex: inout [Int32],
                              cellIDtoNMTs: inout [Int16],
                              indexToPoint: inout [Int32]) -> ([SCNNode], [SCNVector3], [Int], [simd_float3]) {

        // Track progress of cells with completed MTs
        completedMTsCount = Parameters.nMicrotubules // First cell is not computed in parallel, excluded from progress count
        progressFinishedUpdating = true
        startTime = NSDate.now

        // Create all-cells arrays
        nodelist = []
        microtubulePoints = []
        microtubuleNSegments = []
        separateMicrotubulePoints = []

        cellsPointsNumber = []

        // Setup queues for writing to the all-cells arrays (computed concurrently after the first cell)

        threadSafeQueueForArrays = DispatchQueue(label: "Thread-safe write to arrays")
        progressUpdateQueue = DispatchQueue(label: "Progress update queue")

        // Add initial separator
        microtubulePointsArray.append(simd_float3(Parameters.cellRadius, Parameters.cellRadius, Parameters.cellRadius))

        // Generate MTs for the first cell

        DispatchQueue.main.async {
            self.alertLabel?.text = "Generating microtubule structure of the first cell"
        }

        spawnOneCellMicrotubules(microtubulePointsArray: &microtubulePointsArray, isFirstCell: true)

        // Generate MTs for each cell concurrently (will use max available cores)
        DispatchQueue.concurrentPerform(iterations: Parameters.nCells - 1, execute: { _ in
            spawnOneCellMicrotubules(microtubulePointsArray: &microtubulePointsArray, isFirstCell: false)
        })

        computeTabViewController?.MTcollection = separateMicrotubulePoints

        DispatchQueue.main.async {
            self.alertLabel?.text = "Generating microtubule structure: Converting arrays for Metal"
        }

        // Add MTs to the CellID dictionary

        addMTToCellIDDict(cellIDDict: &cellIDDict,
                          points: microtubulePointsArray,
                          cellNMTPoints: cellsPointsNumber,
                          cellRadius: Parameters.cellRadius,
                          cellsPerDimension: Int(Parameters.cellsPerDimension))

        // Convert MT dictionary to arrays

        cellIDDictToArrays(cellIDDict: cellIDDict,
                           cellIDtoIndex: &cellIDtoIndex,
                           cellIDtoNMTs: &cellIDtoNMTs,
                           MTIndexArray: &indexToPoint,
                           nCells: Parameters.nCells,
                           cellsPerDimension: Int(Parameters.cellsPerDimension),
                           alertLabel: alertLabel)

        return (nodelist, microtubulePoints, microtubuleNSegments, microtubulePointsArray)
    }

    // MARK: - Spawn MTs for one cell

    private func spawnOneCellMicrotubules(microtubulePointsArray: inout [simd_float3], isFirstCell: Bool) {

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

            // UI configuration for the first cell (the only cell displayed on screen)
            if isFirstCell {
                let microtubuleColor = UIColor.green.withAlphaComponent(0.0).cgColor
                let geometry = SCNGeometry.lineThrough(points: points,
                                                       width: 2,
                                                       closed: false,
                                                       color: microtubuleColor)
                let node = SCNNode(geometry: geometry)
                scene?.rootNode.addChildNode(node)
                nodelist.append(node)
            }

            // Mark the microtubule as completed and show progress
            progressUpdateQueue?.async {
                guard self.completedMTsCount != nil else { return }
                guard let progressFinishedUpdating = self.progressFinishedUpdating else { return }
                self.completedMTsCount! += 1
                if progressFinishedUpdating {
                    self.updateProgress()
                }
            }
            // Append microtubule
            localSeparateMicrotubulePointsArray.append(localMicrotubule)
        }

        // Update all-cells array with local ones safely
        threadSafeQueueForArrays?.sync {

            microtubulePoints.append(contentsOf: localMicrotubulePoints)
            microtubuleNSegments.append(contentsOf: localMicrotubuleNSegments)
            microtubulePointsArray.append(contentsOf: localMicrotubulePointsArray)

            // Update the length of each cell's MT points
            cellsPointsNumber.append(cellPoints)
            separateMicrotubulePoints.append(contentsOf: localSeparateMicrotubulePointsArray)
        }
    }

}
