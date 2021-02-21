//
//  CellTransportPerformanceTests.swift
//  CellTransportPerformanceTests
//
//  Created by Raúl Montón Pinillos on 20/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import XCTest
import simd

class CellTransportPerformanceTests: XCTestCase {

    private let measureOptions = XCTMeasureOptions()

    override func setUpWithError() throws {
        // This method is called before the invocation of each test method in the class.
        measureOptions.iterationCount = 2
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRebuildCellIDToNMTsArray() throws {
        // Define used variables
        var microtubulePointsArray: [simd_float3] = []
        var cellIDDict: [Int: [Int]] = [Int: [Int]]()
        var cellIDtoIndex: [Int32] = []
        var cellIDtoNMTs: [Int16] = []
        var indexToPoint: [Int32] = []

        // Spawn microtubules
        _ = spawnAllMicrotubules(alertLabel: nil,
                                 scene: nil,
                                 computeTabViewController: nil,
                                 microtubulePointsArray: &microtubulePointsArray,
                                 cellIDDict: &cellIDDict,
                                 cellIDtoIndex: &cellIDtoIndex,
                                 cellIDtoNMTs: &cellIDtoNMTs,
                                 indexToPoint: &indexToPoint)
        // Print cellIDtoNMTs size
        print("indexToPoint size = " + String(indexToPoint.count))
        // Measure rebuild time (best estimation)
        measure(options: measureOptions, block: {
            for i in 0..<(indexToPoint.count - 1) {
                indexToPoint[i] = indexToPoint[i+1]
            }
        })
    }

}
