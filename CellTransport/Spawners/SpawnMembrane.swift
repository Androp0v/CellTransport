//
//  SpawnMembrane.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 12/12/20.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

func spawnCellMembrane(scene: SCNScene) -> [SCNNode]{
    
    var membrane: SCNGeometry
    
    switch parameters.cellShape {
    case parameters.SPHERICAL_CELL:
        membrane = SCNIcosphere(radius: parameters.cellRadius)
    case parameters.CUBIC_CELL:
        membrane = SCNBox(width: CGFloat(2*parameters.cellRadius),
                          height: CGFloat(2*parameters.cellRadius),
                          length: CGFloat(2*parameters.cellRadius),
                          chamferRadius: CGFloat(0.1*parameters.cellRadius))
    default:
        membrane = SCNIcosphere(radius: parameters.cellRadius)
    }
    
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.black
    material.reflective.contents = UIColor(red: 0.2, green: 0.764, blue: 1, alpha: 1)
    material.reflective.intensity = 1
    material.transparent.contents = UIColor.black.withAlphaComponent(0.15)
    material.transparencyMode = .default
    material.fresnelExponent = 4
    
    material.lightingModel = .constant
    material.blendMode = .screen
    material.writesToDepthBuffer = false
    
    membrane.materials = [material]
    
    let membraneNode = SCNNode(geometry: membrane)

    scene.rootNode.addChildNode(membraneNode)
    
    membraneNode.position = SCNVector3(x: 0, y: 0, z: 0)
    
    //Added second sphere membrane for faint base color
    var membrane2: SCNGeometry
    
    switch parameters.cellShape {
    case parameters.SPHERICAL_CELL:
        membrane2 = SCNSphere(radius: CGFloat(parameters.cellRadius*0.99))
        (membrane2 as! SCNSphere).segmentCount = 96
    case parameters.CUBIC_CELL:
        membrane2 = SCNBox(width: CGFloat(2*parameters.cellRadius*0.99),
                           height: CGFloat(2*parameters.cellRadius*0.99),
                           length: CGFloat(2*parameters.cellRadius*0.99),
                           chamferRadius: CGFloat(0.1*parameters.cellRadius*0.99)
        )
    default:
        membrane2 = SCNSphere(radius: CGFloat(parameters.cellRadius*0.99))
        (membrane2 as! SCNSphere).segmentCount = 96
    }
    
    membrane2.firstMaterial?.transparency = 0.05
    membrane2.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.764, blue: 1, alpha: 1)
    membrane2.firstMaterial?.lightingModel = .constant
    let membraneNode2 = SCNNode(geometry: membrane2)
    scene.rootNode.addChildNode(membraneNode2)
    membraneNode2.position = SCNVector3(x: 0, y: 0, z: 0)
    
    return [membraneNode, membraneNode2]
}
