//
//  Microtubules.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import SceneKit
import simd

func generateMicrotubule(centrosomeLocation: SCNVector3) -> [SCNVector3]{
    
    let segmentLength:Float = 0.01
    let cellRadius:Float = 1.0
    let localAngle = 0.15 //1.115265 //Radians, about 63.9º
    
    var pointsList:[SCNVector3] = [centrosomeLocation]
    
    for i in 0...(200){
        
        var newPoint:SCNVector3
        
        if i == 0{
            
            let tmpX = Float.random(in: -1...1)
            let tmpY = Float.random(in: -1...1)
            let tmpZ = Float.random(in: -1...1)
            let normalConstant = sqrt(pow(tmpX, 2) + pow(tmpY, 2) + pow(tmpZ, 2))
            
            newPoint = SCNVector3(centrosomeLocation.x + segmentLength*tmpX/normalConstant,
                                  centrosomeLocation.y + segmentLength*tmpY/normalConstant,
                                  centrosomeLocation.z + segmentLength*tmpZ/normalConstant)
        }else{
            
            let directionvector = SCNVector3((pointsList[i].x - pointsList[i-1].x)/segmentLength,
                                             (pointsList[i].y - pointsList[i-1].y)/segmentLength,
                                             (pointsList[i].z - pointsList[i-1].z)/segmentLength)
            
            newPoint = pointsList[i]
            newPoint.x += directionvector.x*segmentLength*Float(cos(localAngle))
            newPoint.y += directionvector.y*segmentLength*Float(cos(localAngle))
            newPoint.z += directionvector.z*segmentLength*Float(cos(localAngle))
            
            let testX = normalize(cross(normalize(simd_float3(Float.random(in: -1...1),Float.random(in: -1...1),Float.random(in: -1...1))), normalize(simd_float3(directionvector))))
            let testY = normalize(cross(normalize(simd_float3(testX)), normalize(simd_float3(directionvector))))
                        
            let randomPhi = Float.random(in: 0..<(2*Float.pi))
            let xvalue = segmentLength*Float(sin(localAngle))*Float(sin(randomPhi))
            let yvalue = segmentLength*Float(sin(localAngle))*Float(cos(randomPhi))
            
            let randomX = SCNVector3(testX.x*xvalue, testX.y*xvalue, testX.z*xvalue)
            let randomY = SCNVector3(testY.x*yvalue, testY.y*yvalue, testY.z*yvalue)
            
            newPoint.x += randomX.x + randomY.x
            newPoint.y += randomX.y + randomY.y
            newPoint.z += randomX.z + randomY.z
            
        }
        
        // Check wether microtubule has exceeded cell walls
        if (sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2)) > cellRadius){
            return pointsList
        }
        pointsList.append(newPoint)
    }
    
    return pointsList
}
