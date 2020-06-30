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

func generateMicrotubule(cellRadius: Float, centrosomeRadius: Float, centrosomeLocation: SCNVector3) -> [SCNVector3]{
    
    let segmentLength:Float = 20 //0.01*cellRadius
    let localAngle: Float = 0.0 //0.15 //1.115265 //Radians, about 63.9º
    let maxLocalAngle: Float = 1*localAngle
    let angleSlope: Float = (maxLocalAngle - localAngle)/(0.1*cellRadius)
    let maxNSegments = 2000
    
    var pointsList:[SCNVector3] = []
    
    for i in 0..<(maxNSegments-1){
        
        var newPoint:SCNVector3
        
        if i == 0{
            
            //Initialize first microtubule point inside the centrosome
            var p0 = vector_float3(10*centrosomeRadius,10*centrosomeRadius,10*centrosomeRadius)
            repeat{
                p0 = vector_float3(Float.random(in: -centrosomeRadius...centrosomeRadius),Float.random(in: -centrosomeRadius...centrosomeRadius),Float.random(in: -centrosomeRadius...centrosomeRadius))
            } while sqrt(pow(p0.x,2) + pow(p0.y,2) + pow(p0.z,2)) > centrosomeRadius
            
            pointsList.append(SCNVector3(centrosomeLocation.x + p0.x,
                                    centrosomeLocation.y + p0.y,
                                    centrosomeLocation.z + p0.z))
            
            //Initialize second microtubule point (random direction)
            
            let tmpX = pointsList[0].x // Float.random(in: -1...1)
            let tmpY = pointsList[0].y // Float.random(in: -1...1)
            let tmpZ = pointsList[0].z // Float.random(in: -1...1)
            let normalConstant = sqrt(pow(tmpX, 2) + pow(tmpY, 2) + pow(tmpZ, 2))
            
            newPoint = SCNVector3(centrosomeLocation.x + p0.x + segmentLength*tmpX/normalConstant,
                                  centrosomeLocation.y + p0.y + segmentLength*tmpY/normalConstant,
                                  centrosomeLocation.z + p0.z + segmentLength*tmpZ/normalConstant)
        }else{
            
            let directionvector = SCNVector3((pointsList[i].x - pointsList[i-1].x)/segmentLength,
                                             (pointsList[i].y - pointsList[i-1].y)/segmentLength,
                                             (pointsList[i].z - pointsList[i-1].z)/segmentLength)
            
            let currentDistance = sqrt(pow(pointsList[i].x,2) + pow(pointsList[i].y,2) + pow(pointsList[i].z,2))
            
            var localAngleMod = localAngle
            
            if currentDistance > 0.90*cellRadius{
                localAngleMod = localAngle + (currentDistance - 0.90*cellRadius)*angleSlope
            }
            
            newPoint = pointsList[i]
            newPoint.x += directionvector.x*segmentLength*Float(cos(localAngleMod))
            newPoint.y += directionvector.y*segmentLength*Float(cos(localAngleMod))
            newPoint.z += directionvector.z*segmentLength*Float(cos(localAngleMod))
            
            let testX = normalize(cross(normalize(simd_float3(Float.random(in: -1...1),Float.random(in: -1...1),Float.random(in: -1...1))), normalize(simd_float3(directionvector))))
            let testY = normalize(cross(normalize(simd_float3(testX)), normalize(simd_float3(directionvector))))
                        
            let randomPhi = Float.random(in: 0..<(2*Float.pi))
            let xvalue = segmentLength*Float(sin(localAngleMod))*Float(sin(randomPhi))
            let yvalue = segmentLength*Float(sin(localAngleMod))*Float(cos(randomPhi))
            
            let randomX = SCNVector3(testX.x*xvalue, testX.y*xvalue, testX.z*xvalue)
            let randomY = SCNVector3(testY.x*yvalue, testY.y*yvalue, testY.z*yvalue)
            
            newPoint.x += randomX.x + randomY.x
            newPoint.y += randomX.y + randomY.y
            newPoint.z += randomX.z + randomY.z
            
        }
        
        // Check wether microtubule has exceeded cell walls
        if (sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2)) > cellRadius){
            //print("Microtubule length: " + String(pointsList.count))
            return pointsList
        }
        pointsList.append(newPoint)
    }
    
    //print("Microtubule length: " + String(pointsList.count))
    return pointsList
}
