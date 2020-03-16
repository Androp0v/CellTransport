//
//  CellMembrane.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 16/03/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit

func SCNIcosphere(radius: Float, recursionLevel: Int = 5) -> SCNGeometry{
    
    let t = (1.0 + sqrt(5.0)) / 2.0
    
    var vertices: [SCNVector3] = [
        SCNVector3(-1,  t,  0),
        SCNVector3( 1,  t,  0),
        SCNVector3(-1, -t,  0),
        SCNVector3( 1, -t,  0),

        SCNVector3( 0, -1,  t),
        SCNVector3( 0,  1,  t),
        SCNVector3( 0, -1, -t),
        SCNVector3( 0,  1, -t),

        SCNVector3( t,  0, -1),
        SCNVector3( t,  0,  1),
        SCNVector3(-t,  0, -1),
        SCNVector3(-t,  0,  1)
    ]
    
    for i in 0..<vertices.count {
        vertices[i] = SCNVector3(normalize(simd_float3(vertices[i])))
        vertices[i].x *= radius
        vertices[i].y *= radius
        vertices[i].z *= radius
    }
    
    var indices: [UInt16] = [
        0, 11, 5,
        0, 5, 1,
        0, 1, 7,
        0, 7, 10,
        0, 10, 11,

        1, 5, 9,
        5, 11, 4,
        11, 10, 2,
        10, 7, 6,
        7, 1, 8,

        3, 9, 4,
        3, 4, 2,
        3, 2, 6,
        3, 6, 8,
        3, 8, 9,

        4, 9, 5,
        2, 4, 11,
        6, 2, 10,
        8, 6, 7,
        9, 8, 1
    ]
    
    var newVertices: [SCNVector3] = [SCNVector3]()
    var newIndices: [UInt16] = [UInt16]()
    
    for _ in 0..<recursionLevel{
        newVertices = [SCNVector3]()
        newIndices = [UInt16]()
                    
        for j in stride(from: 0, to: indices.count, by: 3){
            let v0 = vertices[Int(indices[j])]
            let v1 = vertices[Int(indices[j+1])]
            let v2 = vertices[Int(indices[j+2])]
                                
            let v3 = SCNVector3(normalize(simd_float3(SCNVector3(0.5*v0.x + 0.5*v1.x, 0.5*v0.y + 0.5*v1.y, 0.5*v0.z + 0.5*v1.z))))
            let v4 = SCNVector3(normalize(simd_float3(SCNVector3(0.5*v1.x + 0.5*v2.x, 0.5*v1.y + 0.5*v2.y, 0.5*v1.z + 0.5*v2.z))))
            let v5 = SCNVector3(normalize(simd_float3(SCNVector3(0.5*v2.x + 0.5*v0.x, 0.5*v2.y + 0.5*v0.y, 0.5*v2.z + 0.5*v0.z))))
            
            var v0index: UInt16
            var v1index: UInt16
            var v2index: UInt16
            var v3index: UInt16
            var v4index: UInt16
            var v5index: UInt16
            
            let tentativeV0 = newVertices.firstIndex(where: { $0.x == v0.x && $0.y == v0.y && $0.z == v0.z})
            if tentativeV0 != nil{
                v0index = UInt16(tentativeV0!)
            }else{
                newVertices.append(v0)
                v0index = UInt16(newVertices.count - 1)
            }
            
            let tentativeV1 = newVertices.firstIndex(where: { $0.x == v1.x && $0.y == v1.y && $0.z == v1.z})
            if tentativeV1 != nil{
                v1index = UInt16(tentativeV1!)
            }else{
                newVertices.append(v1)
                v1index = UInt16(newVertices.count - 1)
            }
            
            let tentativeV2 = newVertices.firstIndex(where: { $0.x == v2.x && $0.y == v2.y && $0.z == v2.z})
            if tentativeV2 != nil{
                v2index = UInt16(tentativeV2!)
            }else{
                newVertices.append(v2)
                v2index = UInt16(newVertices.count - 1)
            }
            
            let tentativeV3 = newVertices.firstIndex(where: { $0.x == v3.x && $0.y == v3.y && $0.z == v3.z})
            if tentativeV3 != nil{
                v3index = UInt16(tentativeV3!)
            }else{
                newVertices.append(v3)
                v3index = UInt16(newVertices.count - 1)
            }
            
            let tentativeV4 = newVertices.firstIndex(where: { $0.x == v4.x && $0.y == v4.y && $0.z == v4.z})
            if tentativeV4 != nil{
                v4index = UInt16(tentativeV4!)
            }else{
                newVertices.append(v4)
                v4index = UInt16(newVertices.count - 1)
            }
            
            let tentativeV5 = newVertices.firstIndex(where: { $0.x == v5.x && $0.y == v5.y && $0.z == v5.z})
            if tentativeV5 != nil{
                v5index = UInt16(tentativeV5!)
            }else{
                newVertices.append(v5)
                v5index = UInt16(newVertices.count - 1)
            }
            
            newIndices.append(v0index)
            newIndices.append(v3index)
            newIndices.append(v5index)
            
            newIndices.append(v3index)
            newIndices.append(v1index)
            newIndices.append(v4index)
            
            newIndices.append(v4index)
            newIndices.append(v2index)
            newIndices.append(v5index)
            
            newIndices.append(v3index)
            newIndices.append(v4index)
            newIndices.append(v5index)
        }
        
        for i in 0..<newVertices.count {
            newVertices[i] = SCNVector3(normalize(simd_float3(newVertices[i])))
            newVertices[i].x *= radius
            newVertices[i].y *= radius
            newVertices[i].z *= radius
        }
        
        vertices = newVertices
        indices = newIndices
        
    }
    
    for i in 0..<newVertices.count {
        newVertices[i].x += radius*Float.random(in: 0..<1)*0.01
        newVertices[i].y += radius*Float.random(in: 0..<1)*0.01
        newVertices[i].z += radius*Float.random(in: 0..<1)*0.01
    }
                            
    let source = SCNGeometrySource(vertices: newVertices)
    let element = SCNGeometryElement(indices: newIndices, primitiveType: .triangles)
    let geometry = SCNGeometry(sources: [source], elements: [element])
    
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.black
    material.reflective.contents = UIColor(red: 0.2, green: 0.764, blue: 1, alpha: 1)
    material.reflective.intensity = 1
    material.transparent.contents = UIColor.black.withAlphaComponent(0.15)
    material.transparencyMode = .default
    material.fresnelExponent = 4
    geometry.materials = [material]
                    
    return geometry
}
