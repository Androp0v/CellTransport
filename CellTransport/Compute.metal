//
//  Compute.metal
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

constant int KINESIN_ONLY = 0;
constant int DYNEIN_ONLY = 1;

constant int REINJECT_INSIDE = 0;
constant int REINJECT_OUTSIDE = 1;
constant int CONTAIN_INSIDE = 2;

constant int OUTSIDE_AND_COUNT_TIME = 0;
constant int INSIDE = 1;
constant int OUTSIDE_AND_NOT_COUNT_TIME = 2;

// MARK: - Compile time constants

constant float deltat [[ function_constant(0) ]];
constant int32_t stepsPerMTPoint [[ function_constant(1) ]];
constant float cellRadius [[ function_constant(2) ]];
constant int32_t cellsPerDimension [[ function_constant(3) ]];
constant int32_t nBodies [[ function_constant(4) ]];
constant int32_t nCells [[ function_constant(5) ]];
constant bool nucleusEnabled [[ function_constant(6) ]];

// MARK: - Input parameters struct

struct simulation_parameters {
    float wON;
    float wOFF;
    float n_w;
    int32_t boundaryConditions;
    int32_t molecularMotors;
    float nucleusRadius;
    simd_float3 nucleusLocation;
    float time;
};

// MARK: - Helper functions

// Get CellID of a position in x,y,z coordinates
int getCellID(float x, float y, float z, float cellRadius, int cellsPerDimension, int currentCellNumber){
    
    int maxCellNumber = cellsPerDimension*cellsPerDimension*cellsPerDimension;
    
    int cellID = 0;
    cellID += cellsPerDimension*cellsPerDimension * int(cellsPerDimension * ((z+cellRadius)/(2*cellRadius)));
    cellID += cellsPerDimension * int(cellsPerDimension * ((y+cellRadius)/(2*cellRadius)));
    cellID += int(cellsPerDimension * ((x+cellRadius)/(2*cellRadius)));
    
    cellID += maxCellNumber*currentCellNumber;
    
    return cellID;
}

// Check if a position is inside the cell nucleus
bool checkIfInsideNucleus(float3 MTPoint, float nucleusRadius, float3 nucleusLocation) {
    // Always return false if the nucleus is not enabled
    if (!nucleusEnabled) {
        return false;
    }
        
    // Check if it's inside the (spherical) nucleus
    if (distance(MTPoint, nucleusLocation) < nucleusRadius) {
        return true;
    } else {
        return false;
    }
}

// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

// Generate random sphere points
float4 randomSpherePoint(float radius, int x, int y, int z){
    
    float u = rand(x, y, z);
    float v = rand(z, x, y);
    float theta = u * 2.0 * M_PI_F;
    float phi = acos(2.0 * v - 1.0);
    float r = radius*pow(rand(y, z, x), 1.0/3.0);
    float sinTheta = sin(theta);
    float cosTheta = cos(theta);
    float sinPhi = sin(phi);
    float cosPhi = cos(phi);
    float xsphere = r * sinPhi * cosTheta;
    float ysphere = r * sinPhi * sinTheta;
    float zsphere = r * cosPhi;
        
    return float4(xsphere,ysphere,zsphere,r);
}

// Generate random sphere surface points
float4 randomSurfaceSpherePoint(float radius, int x, int y, int z){
    
    float u = rand(x, y, z);
    float v = rand(z, x, y);
    float theta = u * 2.0 * M_PI_F;
    float phi = acos(2.0 * v - 1.0);
    float sinTheta = sin(theta);
    float cosTheta = cos(theta);
    float sinPhi = sin(phi);
    float cosPhi = cos(phi);
    float xsphere = radius * sinPhi * cosTheta;
    float ysphere = radius * sinPhi * sinTheta;
    float zsphere = radius * cosPhi;
        
    return float4(xsphere,ysphere,zsphere,radius);
}

// Check if particle is outside bounds
int isOutsideBounds(int32_t boundaryConditions, float distance, float cellRadius) {
    switch (boundaryConditions) {
        case REINJECT_INSIDE: {
            if (distance >= cellRadius){
                return OUTSIDE_AND_COUNT_TIME;
            }else{
                return INSIDE;
            }
        }
        case CONTAIN_INSIDE: {
            if (distance >= cellRadius){
                return OUTSIDE_AND_NOT_COUNT_TIME;
            }else{
                return INSIDE;
            }
        }
        case REINJECT_OUTSIDE:{
            if (distance <= cellRadius*0.1) {
                return OUTSIDE_AND_COUNT_TIME;
            } else if (distance > cellRadius) {
                return OUTSIDE_AND_NOT_COUNT_TIME;
            } else {
                return INSIDE;
            }
        }
        default: {
            if (distance >= cellRadius){
                return OUTSIDE_AND_COUNT_TIME;
            }else{
                return INSIDE;
            }
        }
    }
}

// Retrieve reinjection point for the current boundary conditions
float4 reinjectPosition(int32_t boundaryConditions, float distance, float cellRadius, float3 position, float3 positionOld) {
    switch (boundaryConditions) {
        case REINJECT_INSIDE: {
            // Reinject inside the centrosome
            return randomSpherePoint(0.1 * cellRadius, int(position.x*100000), int(position.y*100000), int(position.z*100000));
        }
        case REINJECT_OUTSIDE: {
            // Reinject at the cell membrane (surface only)
            float almostCellRadius = 0.999*cellRadius; //To avoid z-fighting in membrane
            return randomSurfaceSpherePoint(almostCellRadius, int(position.x*100000), int(position.y*100000), int(position.z*100000));
        }
        case CONTAIN_INSIDE: {
            float distance = sqrt(pow(positionOld.x, 2) + pow(positionOld.y, 2) + pow(positionOld.z, 2));
            return float4(positionOld.x,positionOld.y,positionOld.z,distance);
        }
        default: {
            // Default is like KINESIN_ONLY
            return randomSpherePoint(0.1 * cellRadius, int(position.x*100000), int(position.y*100000), int(position.z*100000));
        }
    }
}

// Check if time should be reset
bool shouldResetTime(int32_t boundaryConditions, float cellRadius, float distance) {
    switch (boundaryConditions) {
        case REINJECT_INSIDE: {
            if (distance < 0.1*cellRadius) {
                return true;
            }
        }
        case REINJECT_OUTSIDE: {
            return false;
        }
        case CONTAIN_INSIDE: {
            return false;
        }
        default: {
            return false;
        }
    }
}

// MARK: - Main compute kernel

kernel void compute(device float3 *positionsIn [[buffer(0)]],
                    device float3 *positionsOut [[buffer(1)]],
                    device float *distances [[buffer(2)]],
                    device float *timeLastJumpIn [[buffer(3)]],
                    device float *timeLastJumpOut [[buffer(4)]],
                    device float *timeBetweenJumps [[buffer(5)]],
                    device simd_float3 *MTpoints [[buffer(6)]],
                    device int32_t *cellIDtoIndex [[buffer(7)]],
                    device int16_t *cellIDtoNMTs [[buffer(8)]],
                    device int32_t *indexToPoints [[buffer(9)]],
                    device int32_t *isAttachedIn [[buffer(10)]],
                    device int32_t *isAttachedOut [[buffer(11)]],
                    device float *randomSeedsIn [[buffer(12)]],
                    device float *randomSeedsOut [[buffer(13)]],
                    device int32_t *MTstepNumberIn [[buffer(14)]],
                    device int32_t *MTstepNumberOut [[buffer(15)]],
                    constant simulation_parameters & parameters [[buffer(16)]],
                    uint i [[thread_position_in_grid]],
                    uint l [[thread_position_in_threadgroup]]) {

    // Create temporal values here for better coalescing of writes
    int32_t isAttached = isAttachedIn[i];
    float3 position = positionsIn[i];
    int32_t MTstepNumber = MTstepNumberIn[i];
    float timeLastJump = timeLastJumpIn[i];

    // Initialize useful values
    int currentCellNumber = int( i / int(nBodies / nCells) );
    
    int currentCellID = getCellID(position.x,
                                  position.y,
                                  position.z,
                                  cellRadius,
                                  cellsPerDimension,
                                  currentCellNumber);
                
    // Flag wether or not the particle should diffuse. Default to true
    bool diffuseFlag = true;

    // Precompute the random number used in MT dynamics
    float randNumber = rand(int(randomSeedsIn[i]*100000), 0, 0);
    
    // MARK: - Microtubule attach/detach
        
    // Check if the particle is currently attached to something (so isAttached != -1)
    if (isAttached != -1) {
        
        // Probability that the particle detaches
        bool willDetach = (randNumber < parameters.wOFF * deltat / stepsPerMTPoint);
        
        // Check that the particle hasn't reached the end of the MT
        bool isAtMTLastPoint = abs(MTpoints[isAttached + 1].x == cellRadius) &&
                                abs(MTpoints[isAttached + 1].y == cellRadius) &&
                                abs(MTpoints[isAttached + 1].z == cellRadius);
        
        // If the particle will naturally detach or is ar the end of a MT, detach
        if (willDetach || isAtMTLastPoint) {
            
            isAttached = -1;
            MTstepNumber = 1;
            
        } else {
            
            // Since we know the particle is currently at a MT, it shouldn't diffuse
            diffuseFlag = false;

            // Check if the particle should advance to the next MTPoint
            if (MTstepNumber >= stepsPerMTPoint) {
                
                int MTdirection;
                
                switch (parameters.molecularMotors) {
                    case KINESIN_ONLY:
                        // Move outward
                        MTdirection = 1;
                        break;
                    case DYNEIN_ONLY:
                        // Move inward
                        MTdirection = -1;
                        break;
                    default:
                        // Default to KINESIN_ONLY
                        MTdirection = 1;
                }
                
                // Move in MTdirection
                position = MTpoints[isAttached + MTdirection];
                isAttached += MTdirection;
                MTstepNumber = 1;
                
            } else {

                MTstepNumber += 1;
                
            }
            
        }
        
    } else {

        // cellVolume is computed as compile time as cellRadius and cellsPerDimension are known at compile time
        float cellVolume = pow(2*cellRadius / cellsPerDimension, 3);
        
        // Probability that the particle attaches
        if (randNumber < 1 - pow(1 - parameters.wON * (deltat / stepsPerMTPoint) / cellVolume, cellIDtoNMTs[currentCellID])){
            
            // Check if it can attach to anything
            if (cellIDtoNMTs[currentCellID] != 0){
                
                int nMTs = cellIDtoNMTs[currentCellID];
                int chosenMT = int(rand(int(position.x*1000000),
                                        int(position.y*1000000),
                                        int(position.z*1000000))
                                   *nMTs);
                
                int MTindex = cellIDtoIndex[currentCellID];
                float3 MTpointOfAttachment = MTpoints[indexToPoints[MTindex + chosenMT]];
                position = MTpointOfAttachment;
                
                isAttached = indexToPoints[MTindex + chosenMT];
                diffuseFlag = false;
            }
            
        }
    }
    
    // Mark: - Diffusion
    
    if (diffuseFlag){
        
        float randNumber1 = rand(int(randNumber*100000), 0, 0);
        float randNumber2 = rand(int(randNumber1*100000), 0, 0);
        float randNumber3 = rand(int(randNumber2*100000), int(randNumber1*100000), 0);
        randNumber = randNumber3;
        
        float randNumberX = 2*rand(int(randNumber1*10000),
                                   int(position.y*10000),
                                   int(position.z*10000)) - 1;

        float randNumberY = 2*rand(int(position.y*10000),
                                   int(randNumber2*10000),
                                   int(position.z*10000)) - 1;

        float randNumberZ = 2*rand(int(position.y*10000),
                                   int(position.x*10000),
                                   int(randNumber3*10000)) - 1;
        
        // Compute the diffusion movement factor (compiler should optimize this)
        float diffusivity = 1.59349 * pow(10.0, 6.0) / parameters.n_w;
        float deltatMT = deltat / stepsPerMTPoint; //REDUCED DELTA T
        float msqdistance = sqrt(6 * diffusivity * deltatMT);
        float factor = msqdistance / 0.8660254038;
        
        position += factor*float3(randNumberX,randNumberY,randNumberZ);
        isAttached = -1;
    }
    
    // Avoid particle diffusing into the nucleus
    if (checkIfInsideNucleus(position, parameters.nucleusRadius, parameters.nucleusLocation)) {
        // Return particle position to initial position
        position = positionsIn[i];
    }
    
    // Precompute distance
    float distance = sqrt(pow(position.x, 2) + pow(position.y, 2) + pow(position.z, 2));
    
    // Ceck if particle is inside centrosome
    if (shouldResetTime(parameters.boundaryConditions, cellRadius, distance)){
        timeLastJump = parameters.time;
    }
    
    // MARK: - Reinjection
    // Check if new point is outside specified boundary conditions
    
    int outsideBounds = isOutsideBounds(parameters.boundaryConditions, distance, cellRadius);
    switch (outsideBounds) {
        case OUTSIDE_AND_COUNT_TIME: {
            timeBetweenJumps[i] = parameters.time - timeLastJump;
            timeLastJump = parameters.time;
            isAttached = -1;
            
            // Reinject point in the correct position given boundary conditions
            float4 point = reinjectPosition(parameters.boundaryConditions,
                                            distance,
                                            cellRadius,
                                            position,
                                            positionsIn[i]);
            
            position.x = point.x;
            position.y = point.y;
            position.z = point.z;
            
            distance = point.w;
            break;
        }
        case OUTSIDE_AND_NOT_COUNT_TIME: {
            isAttached = -1;
            
            // Reinject point in the correct position given boundary conditions
            float4 point = reinjectPosition(parameters.boundaryConditions,
                                            distance,
                                            cellRadius,
                                            position,
                                            positionsIn[i]);
            
            position.x = point.x;
            position.y = point.y;
            position.z = point.z;
            
            distance = point.w;
            break;
        }
        case INSIDE: {
            // Don't do anything
            break;
        }
        default: {
            // Don't do anything
            break;
        }
    }

    // MARK: - Write to buffers
    // Coalesce all writes to buffer at the same time
    isAttachedOut[i] = isAttached;
    positionsOut[i] = position;
    MTstepNumberOut[i] = MTstepNumber;
    randomSeedsOut[i] = randNumber;
    distances[i] = distance;
    timeLastJumpOut[i] = timeLastJump;
    
}

// MARK: - Verify collisions kernel

kernel void verifyCollisions(device float3 *positionsIn [[buffer(0)]],
                             device float3 *positionsOut [[buffer(1)]],
                             device int32_t *isAttachedIn [[buffer(2)]],
                             device int32_t *isAttachedOut [[buffer(3)]],
                             device int32_t *cellIDtoOccupied [[buffer(4)]],
                             device float *distances [[buffer(5)]],
                             constant simulation_parameters & parameters [[buffer(6)]],
                             uint i [[thread_position_in_grid]]){
    
    int particlesPerCell = nBodies / nCells;
    
    //Update the cellIDtoOccupied hypermatrix
    for(int j=0; j < particlesPerCell; j++){
        cellIDtoOccupied[getCellID(positionsIn[j + particlesPerCell*i].x,
                                   positionsIn[j + particlesPerCell*i].y,
                                   positionsIn[j + particlesPerCell*i].z,
                                   cellRadius,
                                   cellsPerDimension,
                                   i)] += 1;
    }
                                 
    //Move each particle in the cell sequentially
    for (int j=0; j < particlesPerCell; j++){
                
        int cellIdIn = getCellID(positionsIn[j + particlesPerCell*i].x,
                                 positionsIn[j + particlesPerCell*i].y,
                                 positionsIn[j + particlesPerCell*i].z,
                                 cellRadius,
                                 cellsPerDimension,
                                 i);
        int cellIdOut = getCellID(positionsOut[j + particlesPerCell*i].x,
                                  positionsOut[j + particlesPerCell*i].y,
                                  positionsOut[j + particlesPerCell*i].z,
                                  cellRadius,
                                  cellsPerDimension,
                                  i);
        
        //Check if it moved into the same cell and if it's the only particle in that cell
        if ((cellIdOut == cellIdIn) || distances[j + particlesPerCell*i] < cellRadius*0.1){
            positionsIn[j + particlesPerCell*i] = positionsOut[j + particlesPerCell*i];
            isAttachedIn[j + particlesPerCell*i] = isAttachedOut[j + particlesPerCell*i];
            //Free the cell just left
            cellIDtoOccupied[cellIdIn] -= 1;
            cellIDtoOccupied[cellIdOut] += 1;
        }else{
            //Check if the new cell is not occupied
            if (cellIDtoOccupied[cellIdOut] == 0){
                //Move the particle
                positionsIn[j + particlesPerCell*i] = positionsOut[j + particlesPerCell*i];
                isAttachedIn[j + particlesPerCell*i] = isAttachedOut[j + particlesPerCell*i];
                //Free the cell just left
                cellIDtoOccupied[cellIdIn] -= 1;
                cellIDtoOccupied[cellIdOut] += 1;
            }else{
                //Keep the particle in the same position
                //The cell will still be occupied
            }
        }
    }
    
    //Clear the whole cellIdtoOccupied hypermatrix
    for(int j=0; j < particlesPerCell; j++){
        cellIDtoOccupied[getCellID(positionsIn[j + particlesPerCell*i].x,
                                   positionsIn[j + particlesPerCell*i].y,
                                   positionsIn[j + particlesPerCell*i].z,
                                   cellRadius,
                                   cellsPerDimension,
                                   i)] = 0;
        cellIDtoOccupied[getCellID(positionsOut[j + particlesPerCell*i].x,
                                positionsOut[j + particlesPerCell*i].y,
                                positionsOut[j + particlesPerCell*i].z,
                                cellRadius,
                                cellsPerDimension,
                                i)] = 0;
    }
    
}
