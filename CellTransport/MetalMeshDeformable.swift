//
//  MetalMeshDeformable.swift
//  DeformableMesh
//
// Copyright (c) 2015 Lachlan Hurst
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Metal
import SceneKit
import UIKit
import MetalKit

struct DeformData {
    var location:vector_float3
    var direction:vector_float3
    var radiusSquared:Float32
    var deformationAmplitude:Float32
    var pad1:Float32
    var pad2:Float32
}


class MetalMeshData {
    
    var geometry:SCNGeometry
    var vertexBuffer1:MTLBuffer
    var vertexBuffer2:MTLBuffer
    var vertexCount:Int
    
    init(
        geometry:SCNGeometry,
        vertexCount:Int,
        vertexBuffer1:MTLBuffer,
        vertexBuffer2:MTLBuffer) {
        self.geometry = geometry
        self.vertexCount = vertexCount
        self.vertexBuffer1 = vertexBuffer1
        self.vertexBuffer2 = vertexBuffer2
    }
    
}

/*
Builds a SceneKit geometry object backed by a Metal buffer
*/
class MetalMeshDeformable {

    class func initializePoints(_ device: MTLDevice, nbodies: Int, cellRadius: Float) -> MetalMeshData {
        
        var pointsList: [vector_float3] = []
        var indexList: [CInt] = []
        let innerSphere = 0.1*cellRadius
                
        
        for _ in 0...(nbodies-1) {
            
            var p0 = vector_float3(10,10,10)
            
            repeat{
                p0 = vector_float3(Float.random(in: -innerSphere...innerSphere),Float.random(in: -innerSphere...innerSphere),Float.random(in: -innerSphere...innerSphere))
            } while sqrt(pow(p0[0],2) + pow(p0[1],2) + pow(p0[2],2)) > innerSphere
                        
            pointsList.append(p0)
            indexList.append(CInt(indexList.count))
            
        }
        
        let vertexFormat = MTLVertexFormat.float3
        
        let vertexBuffer1 = device.makeBuffer(
            bytes: pointsList,
            length: pointsList.count * MemoryLayout<vector_float3>.size
        )
        let vertexBuffer2 = device.makeBuffer(
            bytes: pointsList,
            length: pointsList.count * MemoryLayout<vector_float3>.size
        )
        
        let vertexSource = SCNGeometrySource(
            buffer: vertexBuffer1!,
            vertexFormat: vertexFormat,
            semantic: SCNGeometrySource.Semantic.vertex,
            vertexCount: pointsList.count,
            dataOffset: 0,
            dataStride: MemoryLayout<vector_float3>.size)
        		
        let indexData  = Data(bytes: indexList, count: MemoryLayout<CInt>.size * indexList.count)
        let indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.point,
            primitiveCount: indexList.count,
            bytesPerIndex: MemoryLayout<CInt>.size
        )
                
        indexElement.pointSize = 2 //0.0005
        indexElement.minimumPointScreenSpaceRadius = 2 //0.1
        //indexElement.maximumPointScreenSpaceRadius = 1//150
        
		let geo = SCNGeometry(sources: [vertexSource], elements: [indexElement])
        geo.firstMaterial?.isLitPerPixel = true
        
        return MetalMeshData(
            geometry: geo,
            vertexCount: pointsList.count,
			vertexBuffer1: vertexBuffer1!,
            vertexBuffer2: vertexBuffer2!)
    }

}
