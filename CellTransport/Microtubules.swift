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

let maxStartPointTries = 1000
let maxNextPointTries = 10
let biasMTBending = 0.15

// Distances from a MT point to the cell wall or cell nucleus surface
private func distanceCellWall(MTPoint: SCNVector3) -> Float {
    return parameters.cellRadius - distance(simd_float3(MTPoint), simd_float3(repeating: 0))
}
private func distanceNucleus(MTPoint: SCNVector3) -> Float {
    return distance(simd_float3(MTPoint), simd_float3(parameters.nucleusLocation)) - parameters.nucleusRadius
}

// Check if a MT point is inside the nucleus
private func checkIfInsideNucleus(MTPoint: SCNVector3) -> Bool {
    
    // Always return false if the nucleus is not enabled
    if !parameters.nucleusEnabled {
        return false
    }
        
    // Check if it's inside the (spherical) nucleus
    if distance(simd_float3(MTPoint), simd_float3(parameters.nucleusLocation)) < parameters.nucleusRadius {
        return true
    } else {
        return false
    }
}

// Compute the local angle based on proximity to cell wall or nucleus
private func computeLocalAngle(MTPoint: SCNVector3, angleSlope: Float) -> Float {
        
    // Compute distance to cell wall and nucleus
    let distanceCellWallValue = distanceCellWall(MTPoint: MTPoint)
    let distanceNucleusValue = distanceNucleus(MTPoint: MTPoint)
    
    // Retrieve base localAngle from parameters
    var localAngle = parameters.localAngle
    
    // Compute the angle next segments have, dependant of how close it is to cell wall or nucleus
    if distanceCellWallValue < parameters.nonFreeMTdistance {
        localAngle = max(parameters.localAngle + (parameters.nonFreeMTdistance - distanceCellWallValue)*angleSlope, localAngle)
    }
    if distanceNucleusValue < parameters.nonFreeMTdistance {
        localAngle = max(parameters.localAngle + (parameters.nonFreeMTdistance - distanceNucleusValue)*angleSlope, localAngle)
    }
    
    return localAngle
}

// Try to generate first microtubule pint, fail after maxStartPointTries tries
private func generateFirstMTSegment(centrosomeRadius: Float, centrosomeLocation: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> [SCNVector3]? {
    
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
        if trials > maxStartPointTries {
            return nil
        }
        trials += 1
    } while distance(simd_float3(firstMTPoint), simd_float3(centrosomeLocation)) > centrosomeRadius && !checkIfInsideNucleus(MTPoint: SCNVector3(p0))
        
    //Initialize second microtubule point in an exactly radial direction
    let tmpX = p0.x
    let tmpY = p0.y
    let tmpZ = p0.z
    let normalConstant = sqrt(pow(tmpX, 2) + pow(tmpY, 2) + pow(tmpZ, 2))
    
    let secondMTPoint = SCNVector3(centrosomeLocation.x + p0.x + parameters.microtubuleSegmentLength*tmpX/normalConstant, centrosomeLocation.y + p0.y + parameters.microtubuleSegmentLength*tmpY/normalConstant, centrosomeLocation.z + p0.z + parameters.microtubuleSegmentLength*tmpZ/normalConstant)
    
    return [firstMTPoint,secondMTPoint]
}

// Generate the next MT point. Null if impossible (after maxNextPointTries tries)
private func generateNextMTPoint(directionVector: SCNVector3, lastPoint: SCNVector3, localAngle: Float) -> SCNVector3? {
    
    // Start from last MT point
    var newPoint: SCNVector3 = lastPoint
    
    // Modify direction vector if inside nonFreeMTdistance and current direction is set to collide with the nucleus
    var directionVectorMod = directionVector
    if distanceNucleus(MTPoint: lastPoint) < parameters.nonFreeMTdistance {
        
        // Raytracing
        var willCollide = false
        for i in 1...30 {
            if checkIfInsideNucleus(MTPoint: SCNVector3( simd_float3(lastPoint) + simd_float3(directionVector) * parameters.microtubuleSegmentLength * Float(i))) {
                willCollide = true
                break
            }
        }
        
        // Bias the direction using the normal
        if willCollide {
            let nucleusNormal = normalize(simd_float3(lastPoint) - simd_float3(parameters.nucleusLocation))
            directionVectorMod = SCNVector3(normalize(Float(biasMTBending)*nucleusNormal + simd_float3(directionVector)))
        }
    }
    
    // Move in the direction the last segment is pointing to
    newPoint.x += directionVectorMod.x*parameters.microtubuleSegmentLength*Float(cos(localAngle))
    newPoint.y += directionVectorMod.y*parameters.microtubuleSegmentLength*Float(cos(localAngle))
    newPoint.z += directionVectorMod.z*parameters.microtubuleSegmentLength*Float(cos(localAngle))
    
    // Coordinate system testX, testY where directionVector lies along the z axis
    let testX = normalize(cross(normalize(simd_float3(Float.random(in: -1...1),Float.random(in: -1...1),Float.random(in: -1...1))), normalize(simd_float3(directionVectorMod))))
    let testY = normalize(cross(normalize(simd_float3(testX)), normalize(simd_float3(directionVectorMod))))
        
    // Choose a random phi value and the x,y values in the coordinate system of a cone along the z axis
    let randomPhi = Float.random(in: 0..<(2*Float.pi))
    let xvalue = parameters.microtubuleSegmentLength*Float(sin(localAngle))*Float(sin(randomPhi))
    let yvalue = parameters.microtubuleSegmentLength*Float(sin(localAngle))*Float(cos(randomPhi))
    
    // Move the xvalue, yvalue to the real coordinate system of the cell
    let randomA = SCNVector3(testX.x*xvalue, testX.y*xvalue, testX.z*xvalue)
    let randomB = SCNVector3(testY.x*yvalue, testY.y*yvalue, testY.z*yvalue)
    
    newPoint.x += randomA.x + randomB.x
    newPoint.y += randomA.y + randomB.y
    newPoint.z += randomA.z + randomB.z
        
    // Check that the point is not inside the nucleus, else return nil
    if checkIfInsideNucleus(MTPoint: newPoint) {
        return nil
    } else {
        return newPoint
    }
}


/*- GENERATE A WHOLE MICROTUBULE -*/

func generateMicrotubule(cellRadius: Float, centrosomeRadius: Float, centrosomeLocation: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> [SCNVector3]{
    
    let angleSlope: Float = (parameters.maxLocalAngle - parameters.localAngle)/(parameters.nonFreeMTdistance)
    
    var pointsList:[SCNVector3] = []
    let randomCutoff: Float = 0.0 //Float.random(in: 0.0..<0.0) //TODO
    
    for i in 0..<(parameters.maxNSegments-1){
        
        var newPoint: SCNVector3?
        
        if i == 0{
            
            // Generate first MT segment
            let firstMTSegment = generateFirstMTSegment(centrosomeRadius: centrosomeRadius, centrosomeLocation: centrosomeLocation, nucleusRadius: nucleusRadius, nucleusLocation: nucleusLocation)
            
            // Append first MT segment, crash if nil
            pointsList.append(firstMTSegment![0])
            pointsList.append(firstMTSegment![1])
            
        }else{
            
            // Once there is at least one MT point created
            let directionVector = SCNVector3((pointsList[i].x - pointsList[i-1].x)/parameters.microtubuleSegmentLength,
                                             (pointsList[i].y - pointsList[i-1].y)/parameters.microtubuleSegmentLength,
                                             (pointsList[i].z - pointsList[i-1].z)/parameters.microtubuleSegmentLength)
            
            // Compute local angle based on distance to cell wall or nucleus
            let localAngleMod = computeLocalAngle(MTPoint: pointsList[i], angleSlope: angleSlope)
            
            // Repeat until a valid (non-null) point is found or until maxNextPointTries is reached
            var nextPointTries: Int = 0
            repeat {
                newPoint = generateNextMTPoint(directionVector: directionVector, lastPoint: pointsList[i], localAngle: localAngleMod)
                nextPointTries += 1
            } while newPoint == nil && nextPointTries < maxNextPointTries
            
            // Check wether next MT point has exceeded cell walls or couldn't be created (null)
            if newPoint == nil {
                return pointsList
            } else {
                if distance(simd_float3(newPoint!), simd_float3(0,0,0)) > cellRadius*(1.0-randomCutoff) {
                    return pointsList
                }
            }
            
            // Append new MT point to list now that it's been verified to be valid
            pointsList.append(newPoint!)
        }
    }
    
    // Return MT if maximum MT segments is reached
    return pointsList
}
