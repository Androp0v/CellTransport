//
//  CellMembrane.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 16/03/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit

func SCNIcosphere(radius: Float, recursionLevel: Int = 7) -> SCNGeometry{
    
    let t: Float = (1.0 + sqrt(5.0)) / 2.0
    
    var vertices: [simd_float3:  UInt32] = [
        simd_float3(-1,  t,  0): 0,
        simd_float3( 1,  t,  0): 1,
        simd_float3(-1, -t,  0): 2,
        simd_float3( 1, -t,  0): 3,

        simd_float3( 0, -1,  t): 4,
        simd_float3( 0,  1,  t): 5,
        simd_float3( 0, -1, -t): 6,
        simd_float3( 0,  1, -t): 7,

        simd_float3( t,  0, -1): 8,
        simd_float3( t,  0,  1): 9,
        simd_float3(-t,  0, -1): 10,
        simd_float3(-t,  0,  1): 11
    ]
    var verticesList: [simd_float3] = [
        simd_float3(-1,  t,  0),
        simd_float3( 1,  t,  0),
        simd_float3(-1, -t,  0),
        simd_float3( 1, -t,  0),

        simd_float3( 0, -1,  t),
        simd_float3( 0,  1,  t),
        simd_float3( 0, -1, -t),
        simd_float3( 0,  1, -t),

        simd_float3( t,  0, -1),
        simd_float3( t,  0,  1),
        simd_float3(-t,  0, -1),
        simd_float3(-t,  0,  1)
    ]
    
    var tempVertices: [simd_float3:  UInt32] = [simd_float3: UInt32]()
    for (vertex, index) in vertices {
        let newVertex = normalize(simd_float3(vertex))
        tempVertices[newVertex] = index
    }
    vertices = tempVertices
    
    for i in 0..<verticesList.count {
        verticesList[i] = normalize(simd_float3(verticesList[i]))
    }
    
    var indices: [UInt32] = [
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
    
    //Initialize noise
    
    let noise = GKNoise.init(GKPerlinNoiseSource())
    var vertexNoise: [simd_float3:  Float] = [simd_float3: Float]()
    
    //Temp arrays and dictionaries
    var newVertices: [simd_float3:  UInt32] = [simd_float3: UInt32]()
    var newVerticesList: [simd_float3] = [simd_float3]()
    var newIndices: [UInt32] = [UInt32]()
            
    //Recursive loop
    for currentRecursionLevel in 0..<recursionLevel{
        newVertices = [simd_float3: UInt32]()
        newVerticesList = [simd_float3]()
        newIndices = [UInt32]()
                    
        for j in stride(from: 0, to: indices.count, by: 3){
            let v0 = verticesList[Int(indices[j])]
            let v1 = verticesList[Int(indices[j+1])]
            let v2 = verticesList[Int(indices[j+2])]
                                
            let v3 = normalize(simd_float3(0.5*v0.x + 0.5*v1.x, 0.5*v0.y + 0.5*v1.y, 0.5*v0.z + 0.5*v1.z))
            let v4 = normalize(simd_float3(0.5*v1.x + 0.5*v2.x, 0.5*v1.y + 0.5*v2.y, 0.5*v1.z + 0.5*v2.z))
            let v5 = normalize(simd_float3(0.5*v2.x + 0.5*v0.x, 0.5*v2.y + 0.5*v0.y, 0.5*v2.z + 0.5*v0.z))
            
            var v0index: UInt32
            var v1index: UInt32
            var v2index: UInt32
            var v3index: UInt32
            var v4index: UInt32
            var v5index: UInt32
            
            //Add vertices to list and cache (dictionary)
            
            if newVertices[v0] != nil{
                v0index = newVertices[v0]!
            }else{
                newVerticesList.append(v0)
                v0index = UInt32(newVerticesList.count - 1)
                newVertices[v0] = v0index
            }
            
            if newVertices[v1] != nil{
                v1index = newVertices[v1]!
            }else{
                newVerticesList.append(v1)
                v1index = UInt32(newVerticesList.count - 1)
                newVertices[v1] = v1index
            }
            
            if newVertices[v2] != nil{
                v2index = newVertices[v2]!
            }else{
                newVerticesList.append(v2)
                v2index = UInt32(newVerticesList.count - 1)
                newVertices[v2] = v2index
            }
            
            if newVertices[v3] != nil{
                v3index = newVertices[v3]!
            }else{
                newVerticesList.append(v3)
                v3index = UInt32(newVerticesList.count - 1)
                newVertices[v3] = v3index
            }
            
            if newVertices[v4] != nil{
                v4index = newVertices[v4]!
            }else{
                newVerticesList.append(v4)
                v4index = UInt32(newVerticesList.count - 1)
                newVertices[v4] = v4index
            }
            
            if newVertices[v5] != nil{
                v5index = newVertices[v5]!
            }else{
                newVerticesList.append(v5)
                v5index = UInt32(newVerticesList.count - 1)
                newVertices[v5] = v5index
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
            
            if currentRecursionLevel > 2{
                if newVertices[v3] != nil{
                    vertexNoise[v3] = (vertexNoise[v0]! + vertexNoise[v1]!)/2
                }
                
                if newVertices[v4] != nil{
                    vertexNoise[v4] = (vertexNoise[v1]! + vertexNoise[v2]!)/2
                }
                
                if newVertices[v5] != nil{
                    vertexNoise[v5] = (vertexNoise[v0]! + vertexNoise[v2]!)/2
                }
            }
            
        }
        
        if currentRecursionLevel == 2{
            
            var semifinalVertices: [SCNVector3] = [SCNVector3]()
            for i in 0..<newVerticesList.count {
                semifinalVertices.append(SCNVector3(radius*newVerticesList[i].x, radius*newVerticesList[i].y, radius*newVerticesList[i].z))
            }
            
            for i in 0..<semifinalVertices.count{
                                    
                noise.move(by: vector_double3(0,0,Double(semifinalVertices[i].z)))
                
                let rDirection = normalize(simd_float3(semifinalVertices[i]))
                let xPosition = semifinalVertices[i].x
                let yPosition = semifinalVertices[i].y
                            
                let noiseValue = noise.value(atPosition: vector_float2(xPosition,yPosition))
                let modulator: Float = 0.000001
                                    
                vertexNoise[newVerticesList[i]] = noiseValue*modulator
                
                semifinalVertices[i].x += rDirection.x * noiseValue * modulator
                semifinalVertices[i].y += rDirection.y * noiseValue * modulator
                semifinalVertices[i].z += rDirection.z * noiseValue * modulator
                
                noise.move(by: vector_double3(0,0,Double(-semifinalVertices[i].z)))
                
            }
            
        }
                    
        vertices = newVertices
        verticesList = newVerticesList
        indices = newIndices
        
    }
    
    //Smoothen noise
    /*for j in stride(from: 0, to: indices.count, by: 3){
        let v0 = verticesList[Int(indices[j])]
        let v1 = verticesList[Int(indices[j+1])]
        let v2 = verticesList[Int(indices[j+2])]
        
        vertexNoise[v0]! = (vertexNoise[v1]! + vertexNoise[v2]!)/2
        vertexNoise[v1]! = (vertexNoise[v0]! + vertexNoise[v2]!)/2
        vertexNoise[v2]! = (vertexNoise[v0]! + vertexNoise[v1]!)/2
    }*/
    
    //Add noise
    for i in 0..<newVerticesList.count{
        var noiseValue = vertexNoise[newVerticesList[i]]
        let rDirection = normalize(newVerticesList[i])
                
        newVerticesList[i].x += rDirection.x * (noiseValue ?? 0.0) * radius
        newVerticesList[i].y += rDirection.y * (noiseValue ?? 0.0) * radius
        newVerticesList[i].z += rDirection.z * (noiseValue ?? 0.0) * radius
    }
    
    //Convert to SCNVector3
    var finalVertices: [SCNVector3] = [SCNVector3]()
    for i in 0..<newVerticesList.count {
        finalVertices.append(SCNVector3(radius*newVerticesList[i].x, radius*newVerticesList[i].y, radius*newVerticesList[i].z))
    }
                    
    //Uniform noise
    for i in 0..<finalVertices.count {
        finalVertices[i].x += radius*Float.random(in: -1..<1)*0.0025
        finalVertices[i].y += radius*Float.random(in: -1..<1)*0.0025
        finalVertices[i].z += radius*Float.random(in: -1..<1)*0.0025
    }
                            
    //Make SceneKit things
    let source = SCNGeometrySource(vertices: finalVertices)
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
