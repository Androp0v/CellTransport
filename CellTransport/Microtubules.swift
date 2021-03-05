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
import GameKit // Gaussian distribution is here

let maxStartPointTries = 1000
let maxNextPointTries = 10
let bendingStrength = 0.2

/// Distances from a MT point to the cell wall or cell nucleus surface
private func distanceCellWall(MTPoint: SCNVector3) -> Float {
    return Parameters.cellRadius - distance(simd_float3(MTPoint), simd_float3(repeating: 0))
}
private func distanceNucleus(MTPoint: SCNVector3) -> Float {
    return distance(simd_float3(MTPoint), simd_float3(Parameters.nucleusLocation)) - Parameters.nucleusRadius
}

/// Check if a MT point is inside the nucleus
private func checkIfInsideNucleus(MTPoint: SCNVector3) -> Bool {
    
    // Always return false if the nucleus is not enabled
    if !Parameters.nucleusEnabled {
        return false
    }
        
    // Check if it's inside the (spherical) nucleus
    if distance(simd_float3(MTPoint), simd_float3(Parameters.nucleusLocation)) < Parameters.nucleusRadius {
        return true
    } else {
        return false
    }
}

/// Check if a MT point is outside the cell
private func checkIfOutsideCell(MTPoint: SCNVector3) -> Bool {
    
    switch Parameters.cellShape {
    case Parameters.SPHERICAL_CELL:
        // Check if it's inside the (spherical) cell
        if distance(simd_float3(MTPoint), simd_float3(repeating: 0)) > Parameters.cellRadius {
            return true
        } else {
            return false
        }
    case Parameters.ORTHOGONAL_CELL:
        // Check if it's inside the (orthogonal) cell
        if MTPoint.x > Parameters.cellWidth / 2 ||
            MTPoint.x < -Parameters.cellWidth / 2 ||
            MTPoint.y > Parameters.cellHeight / 2 ||
            MTPoint.y < -Parameters.cellHeight / 2 ||
            MTPoint.z > Parameters.cellLength / 2 ||
            MTPoint.z < -Parameters.cellLength / 2 {
            return true
        } else {
            return false
        }
    default:
        // Check if it's inside the (spherical) cell
        if distance(simd_float3(MTPoint), simd_float3(repeating: 0)) > Parameters.cellRadius {
            return true
        } else {
            return false
        }
    }
    
}

/// Compute the local angle based on proximity to cell wall or nucleus
private func computeLocalAngle(MTPoint: SCNVector3, angleSlope: Float) -> Float {
    
    // Check that the local angle is not a constant
    if Parameters.maxLocalAngle == Parameters.localAngle {
        return Parameters.localAngle
    }
        
    // Compute distance to cell wall and nucleus (if present)
    let distanceCellWallValue = distanceCellWall(MTPoint: MTPoint)
    
    var distanceNucleusValue: Float = 0
    if Parameters.nucleusEnabled {
        distanceNucleusValue = distanceNucleus(MTPoint: MTPoint)
    }
    
    // Retrieve base localAngle from parameters
    var localAngle = Parameters.localAngle
    
    // Compute the angle next segments have, dependant of how close it is to cell wall or nucleus
    if distanceCellWallValue < Parameters.nonFreeMTdistance {
        localAngle = max(Parameters.localAngle + (Parameters.nonFreeMTdistance - distanceCellWallValue)*angleSlope, localAngle)
    }
    if distanceNucleusValue < Parameters.nonFreeMTdistance && Parameters.nucleusEnabled {
        localAngle = max(Parameters.localAngle + (Parameters.nonFreeMTdistance - distanceNucleusValue)*angleSlope, localAngle)
    }
    
    return localAngle
}

// Try to generate first microtubule pint, fail after maxStartPointTries tries
private func generateFirstMTSegment(centrosomeRadius: Float,
                                    centrosomeLocation: SCNVector3,
                                    nucleusRadius: Float,
                                    nucleusLocation: SCNVector3) -> [SCNVector3]? {

    switch Parameters.microtubulePreferredDirection {
    case Parameters.SPHERICAL_CELL:
        // Initialize first microtubule point inside the centrosome
        var mtPoint: vector_float3
        var trials: Int = 0
        var firstMTPoint: SCNVector3

        // Try to generate a valid starting point or return nil after too many trials
        repeat {
            // Generate a random point and move it relative to the centrosome radius
            mtPoint = vector_float3(Float.random(in: -centrosomeRadius...centrosomeRadius),
                                    Float.random(in: -centrosomeRadius...centrosomeRadius),
                                    Float.random(in: -centrosomeRadius...centrosomeRadius))
            firstMTPoint = SCNVector3(centrosomeLocation.x + mtPoint.x, centrosomeLocation.y + mtPoint.y, centrosomeLocation.z + mtPoint.z)
            // Return nil if too many trials happen
            if trials > maxStartPointTries {
                return nil
            }
            trials += 1
        } while distance(simd_float3(firstMTPoint), simd_float3(centrosomeLocation)) > centrosomeRadius
            && !checkIfInsideNucleus(MTPoint: SCNVector3(mtPoint))

        // Initialize second microtubule point in an exactly radial direction
        let tmpX = mtPoint.x
        let tmpY = mtPoint.y
        let tmpZ = mtPoint.z
        let normalConstant = sqrt(pow(tmpX, 2) + pow(tmpY, 2) + pow(tmpZ, 2))

        let secondMTPoint = SCNVector3(centrosomeLocation.x + mtPoint.x + Parameters.microtubuleSegmentLength*tmpX/normalConstant,
                                       centrosomeLocation.y + mtPoint.y + Parameters.microtubuleSegmentLength*tmpY/normalConstant,
                                       centrosomeLocation.z + mtPoint.z + Parameters.microtubuleSegmentLength*tmpZ/normalConstant)

        return [firstMTPoint, secondMTPoint]
    case Parameters.ORTHOGONAL_CELL:
        // Initialize first microtubule point on the upper cell surface (XY plane)
        var firstMTPoint: SCNVector3

        // Generate a single point on the surface
        firstMTPoint = SCNVector3(Float.random(in: -Parameters.cellWidth/2...Parameters.cellWidth/2),
                                  Parameters.cellHeight/2 - Float.random(in: 0...Parameters.centrosomeRadius),
                                  Float.random(in: -Parameters.cellLength/2...Parameters.cellLength/2))

        // Initialize second microtubule point in an exactly apical-basal direction
        let secondMTPoint = SCNVector3(firstMTPoint.x, firstMTPoint.y - Parameters.microtubuleSegmentLength, firstMTPoint.z)

        return [firstMTPoint, secondMTPoint]
    default:
        return nil
    }
}

/// Generate the next MT point.
/// - Parameters:
///   - directionVector: Direction vector of previous MT segment.
///   - lastPoint: Position of last MT point.
///   - localAngle: Local angle of the cone in which the next point is to be generated.
/// - Returns: SCNVector3? with the new MT position. Null if impossible (after maxNextPointTries tries).
private func generateNextMTPoint(directionVector: SCNVector3, lastPoint: SCNVector3, localAngle: Float) -> SCNVector3? {
    
    // Start from last MT point
    var newPoint: SCNVector3 = lastPoint
    
    // Modify direction vector if inside nonFreeMTdistance and current direction is set to collide with the nucleus
    var directionVectorMod = directionVector
    
    if Parameters.bendMTs {
        if distanceNucleus(MTPoint: lastPoint) < Parameters.nonFreeMTdistance || distanceCellWall(MTPoint: lastPoint) < Parameters.nonFreeMTdistance {
            
            // Raytracing
            var willCollideNucleus = false
            var willCollideCellWall = false
            for i in (1...Int(Parameters.nonFreeMTdistance/Parameters.microtubuleSegmentLength)).reversed() {
                if checkIfInsideNucleus(MTPoint: SCNVector3( simd_float3(lastPoint) + simd_float3(directionVector)
                                                                * Parameters.microtubuleSegmentLength
                                                                * Float(i))) {
                    willCollideNucleus = true
                    break
                } else if checkIfOutsideCell(MTPoint: SCNVector3( simd_float3(lastPoint) + simd_float3(directionVector)
                                                                    * Parameters.microtubuleSegmentLength
                                                                    * Float(i))) {
                    willCollideCellWall = true
                    break
                }
            }
            
            // Bias the direction using the normal
            if willCollideNucleus {
                let nucleusNormal = normalize(simd_float3(lastPoint) - simd_float3(Parameters.nucleusLocation))
                let biasMTBending = Float(bendingStrength) * (1 - distanceNucleus(MTPoint: lastPoint)/Parameters.nonFreeMTdistance)
                directionVectorMod = SCNVector3(normalize(Float(biasMTBending)*nucleusNormal + simd_float3(directionVector)))
            } else if willCollideCellWall {
                let cellWallNormal = -normalize(simd_float3(lastPoint))
                let biasMTBending = Float(bendingStrength) * (1 - distanceCellWall(MTPoint: lastPoint)/Parameters.nonFreeMTdistance)
                directionVectorMod = SCNVector3(normalize(Float(biasMTBending)*cellWallNormal + simd_float3(directionVector)))
            }
        }
    }
    
    // Move in the direction the last segment is pointing to
    newPoint.x += directionVectorMod.x*Parameters.microtubuleSegmentLength*Float(cos(localAngle))
    newPoint.y += directionVectorMod.y*Parameters.microtubuleSegmentLength*Float(cos(localAngle))
    newPoint.z += directionVectorMod.z*Parameters.microtubuleSegmentLength*Float(cos(localAngle))
    
    // Coordinate system testX, testY where directionVector lies along the z axis

    let testX = normalize(cross(normalize(simd_float3(Float.random(in: -1...1),
                                                      Float.random(in: -1...1),
                                                      Float.random(in: -1...1))),
                                normalize(simd_float3(directionVectorMod))))

    let testY = normalize(cross(normalize(simd_float3(testX)),
                                normalize(simd_float3(directionVectorMod))))
        
    // Choose a random phi value and the x,y values in the coordinate system of a cone along the z axis
    let randomPhi = Float.random(in: 0..<(2*Float.pi))
    let xvalue = Parameters.microtubuleSegmentLength*Float(sin(localAngle))*Float(sin(randomPhi))
    let yvalue = Parameters.microtubuleSegmentLength*Float(sin(localAngle))*Float(cos(randomPhi))
    
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

func generateMicrotubule(cellRadius: Float, centrosomeRadius: Float, centrosomeLocation: SCNVector3, nucleusRadius: Float, nucleusLocation: SCNVector3) -> [SCNVector3] {
    
    // Set a target length for the MT to reach
    var targetLength: Float = MAXFLOAT
    if Parameters.bendMTs {
        let randomSource = GKRandomSource()
        let gaussianDistribution = GKGaussianDistribution(randomSource: randomSource, mean: 1500, deviation: 500)
        let randomGaussian = Float(gaussianDistribution.nextInt())/1000
        targetLength = randomGaussian*Parameters.cellRadius
    }

    // Compute the angle slope for MT points near the nucleus or cell wall
    let angleSlope: Float = (Parameters.maxLocalAngle - Parameters.localAngle)/(Parameters.nonFreeMTdistance)
    
    var pointsList: [SCNVector3] = []
    
    // Loop over the maximum number of segments
    for i in 0..<(Parameters.maxNSegments-1) {
        
        var newPoint: SCNVector3?
        
        if i == 0 {
            
            // Generate first MT segment
            let firstMTSegment = generateFirstMTSegment(centrosomeRadius: centrosomeRadius,
                                                        centrosomeLocation: centrosomeLocation,
                                                        nucleusRadius: nucleusRadius,
                                                        nucleusLocation: nucleusLocation)
            
            // Append first MT segment, crash if nil
            pointsList.append(firstMTSegment![0])
            pointsList.append(firstMTSegment![1])
            
        } else {
            
            // Once there is at least one MT point created
            let directionVector = SCNVector3((pointsList[i].x - pointsList[i-1].x)/Parameters.microtubuleSegmentLength,
                                             (pointsList[i].y - pointsList[i-1].y)/Parameters.microtubuleSegmentLength,
                                             (pointsList[i].z - pointsList[i-1].z)/Parameters.microtubuleSegmentLength)
            
            // Compute local angle based on distance to cell wall or nucleus
            let localAngleMod = computeLocalAngle(MTPoint: pointsList[i], angleSlope: angleSlope)
            
            // Repeat until a valid (non-null) point is found or until maxNextPointTries is reached
            var nextPointTries: Int = 0
            repeat {
                newPoint = generateNextMTPoint(directionVector: directionVector, lastPoint: pointsList[i], localAngle: localAngleMod)
                nextPointTries += 1
            } while newPoint == nil && nextPointTries < maxNextPointTries && Parameters.bendMTs
            
            // Check wether next MT point has exceeded cell walls or couldn't be created (null)
            if newPoint == nil {
                return pointsList
            } else if checkIfOutsideCell(MTPoint: newPoint!) {
                return pointsList
            } else if Float(pointsList.count)*Parameters.microtubuleSegmentLength > targetLength {
                return pointsList
            }
            
            // Append new MT point to list now that it's been verified to be valid
            pointsList.append(newPoint!)
        }
    }
    
    // Return MT if maximum MT segments is reached
    return pointsList
}
