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

// Check if a MT point is inside the nucleus
func checkIfInsideNucleus(MTPoint: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> Bool {
    
    // Always return false if the nucleus is not enabled
    if !parameters.nucleusEnabled {
        return false
    }
        
    // Check if it's inside the (spherical) nucleus
    if distance(simd_float3(MTPoint), simd_float3(nucleusLocation)) < nucleusRadius {
        return true
    } else {
        return false
    }
    
}

// Try to generate first microtubule pint, fail after 1000 tries
func generateFirstMTSegment(centrosomeRadius: Float, centrosomeLocation: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> [SCNVector3]? {
    
    // Initialize first microtubule point inside the centrosome
    var p0: vector_float3
    var trials: Int = 0
    var firstMTPoint: SCNVector3
    
    // Try to generate a valid starting point or return nil after too many trials
    repeat{
        // Generate a random point and move it relative to the centrosome radius
        p0 = vector_float3(Float.random(in: -centrosomeRadius...centrosomeRadius),Float.random(in: -centrosomeRadius...centrosomeRadius),Float.random(in: -centrosomeRadius...centrosomeRadius))
        firstMTPoint = SCNVector3(centrosomeLocation.x + p0.x, centrosomeLocation.y + p0.y, centrosomeLocation.z + p0.z)
        // Return nil if too many trials happen
        if trials > 1000 {
            return nil
        }
        trials += 1
    } while distance(simd_float3(firstMTPoint), simd_float3(centrosomeLocation)) > centrosomeRadius && !checkIfInsideNucleus(MTPoint: SCNVector3(p0), nucleusRadius: nucleusRadius, nucleusLocation: nucleusLocation)
        
    //Initialize second microtubule point in an exactly radial direction
    let tmpX = firstMTPoint.x
    let tmpY = firstMTPoint.y
    let tmpZ = firstMTPoint.z
    let normalConstant = sqrt(pow(tmpX, 2) + pow(tmpY, 2) + pow(tmpZ, 2))
    
    let secondMTPoint = SCNVector3(centrosomeLocation.x + p0.x + parameters.microtubuleSegmentLength*tmpX/normalConstant, centrosomeLocation.y + p0.y + parameters.microtubuleSegmentLength*tmpY/normalConstant, centrosomeLocation.z + p0.z + parameters.microtubuleSegmentLength*tmpZ/normalConstant)
    
    return [firstMTPoint,secondMTPoint]
}

// Generate a whole microtubule
func generateMicrotubule(cellRadius: Float, centrosomeRadius: Float, centrosomeLocation: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> [SCNVector3]{
    
    let angleSlope: Float = (parameters.maxLocalAngle - parameters.localAngle)/(0.1*cellRadius)
    
    var pointsList:[SCNVector3] = []
    let randomCutoff: Float = 0.0 //Float.random(in: 0.0..<0.0) //TODO
    
    for i in 0..<(parameters.maxNSegments-1){
        
        var newPoint:SCNVector3
        
        if i == 0{
            
            // Generate first MT segment
            let firstMTSegment = generateFirstMTSegment(centrosomeRadius: centrosomeRadius, centrosomeLocation: centrosomeLocation, nucleusRadius: nucleusRadius, nucleusLocation: nucleusLocation)
            
            // Append first MT segment, crash if nil
            pointsList.append(firstMTSegment![0])
            pointsList.append(firstMTSegment![1])
            
        }else{
            
            // Once there is at least one MT point created
            let directionvector = SCNVector3((pointsList[i].x - pointsList[i-1].x)/parameters.microtubuleSegmentLength,
                                             (pointsList[i].y - pointsList[i-1].y)/parameters.microtubuleSegmentLength,
                                             (pointsList[i].z - pointsList[i-1].z)/parameters.microtubuleSegmentLength)
            
            let currentDistance = sqrt(pow(pointsList[i].x,2) + pow(pointsList[i].y,2) + pow(pointsList[i].z,2))
            
            var localAngleMod = parameters.localAngle
            
            if currentDistance > 0.90*cellRadius{
                localAngleMod = parameters.localAngle + (currentDistance - 0.90*cellRadius)*angleSlope
            }
            
            newPoint = pointsList[i]
            newPoint.x += directionvector.x*parameters.microtubuleSegmentLength*Float(cos(localAngleMod))
            newPoint.y += directionvector.y*parameters.microtubuleSegmentLength*Float(cos(localAngleMod))
            newPoint.z += directionvector.z*parameters.microtubuleSegmentLength*Float(cos(localAngleMod))
            
            let testX = normalize(cross(normalize(simd_float3(Float.random(in: -1...1),Float.random(in: -1...1),Float.random(in: -1...1))), normalize(simd_float3(directionvector))))
            let testY = normalize(cross(normalize(simd_float3(testX)), normalize(simd_float3(directionvector))))
                        
            let randomPhi = Float.random(in: 0..<(2*Float.pi))
            let xvalue = parameters.microtubuleSegmentLength*Float(sin(localAngleMod))*Float(sin(randomPhi))
            let yvalue = parameters.microtubuleSegmentLength*Float(sin(localAngleMod))*Float(cos(randomPhi))
            
            let randomX = SCNVector3(testX.x*xvalue, testX.y*xvalue, testX.z*xvalue)
            let randomY = SCNVector3(testY.x*yvalue, testY.y*yvalue, testY.z*yvalue)
            
            newPoint.x += randomX.x + randomY.x
            newPoint.y += randomX.y + randomY.y
            newPoint.z += randomX.z + randomY.z
            
            // Check wether microtubule has exceeded cell walls
            if distance(simd_float3(newPoint), simd_float3(0,0,0)) > cellRadius*(1.0-randomCutoff) || checkIfInsideNucleus(MTPoint: newPoint, nucleusRadius: nucleusRadius, nucleusLocation: nucleusLocation){
                //print("Microtubule length: " + String(pointsList.count))
                return pointsList
            }
            pointsList.append(newPoint)
            
        }

    }
    
    //print("Microtubule length: " + String(pointsList.count))
    return pointsList
}
