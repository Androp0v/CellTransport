//
//  SpawnCellNucleus.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 20/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

func spawnCellNucleus() -> SCNNode {
    var nucleus: SCNGeometry
    // Generate nucleus as a perlin-noise biased icosphere. Low recursion level (vertex nuber) since texture will make it look good anyway
    nucleus = SCNIcosphere(radius: Parameters.nucleusRadius, recursionLevel: 4, translucid: false, modulator: 0.00001, allowTexture: true)
    // Base color purple, not seen unless no image is found
    nucleus.firstMaterial?.diffuse.contents = UIColor.purple
    // Cellular nucleus texture
    nucleus.firstMaterial?.diffuse.contents = UIImage(named: "cellmembrane.png")

    // Create and move the SceneKit nodes
    let nucleusNode = SCNNode(geometry: nucleus)
    let nucleusAxis = SCNNode()
    nucleusAxis.addChildNode(nucleusNode)

    nucleusAxis.position = SCNVector3(x: 0, y: 0, z: 0)
    nucleusNode.position = Parameters.nucleusLocation

    return nucleusAxis
}
