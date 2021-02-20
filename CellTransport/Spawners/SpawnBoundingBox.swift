//
//  SpawnBoundingBox.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 20/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

func spawnBoundingBox() -> SCNNode {

    var boundingBox: SCNGeometry

    boundingBox = SCNBox(width: CGFloat(2.0*Parameters.cellRadius),
                         height: CGFloat(2.0*Parameters.cellRadius), length: CGFloat(2.0*Parameters.cellRadius),
                         chamferRadius: 0.0)
    boundingBox.firstMaterial?.fillMode = .lines
    boundingBox.firstMaterial?.isDoubleSided = true
    boundingBox.firstMaterial?.diffuse.contents = UIColor.white
    boundingBox.firstMaterial?.transparency = 0.05

    let boundingBoxNode = SCNNode(geometry: boundingBox)

    return boundingBoxNode
}
