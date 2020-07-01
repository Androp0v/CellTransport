//
//  Compute.metal
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

#include <metal_stdlib>

#define wON 0.9
#define wOFF 0.99

using namespace metal;

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

// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

//Generate random sphere points
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

//Try argument struct
struct simulation_parameters {
    float deltat;
    float cellRadius;
    int32_t cellsPerDimension;
    int32_t nBodies;
    int32_t nCells;
};

kernel void compute(device float3 *positionsIn [[buffer(0)]],
                    device float3 *positionsOut [[buffer(1)]],
                    device float *distances [[buffer(2)]],
                    device float *timeLastJump [[buffer(3)]],
                    device float *updatedTimeLastJump [[buffer(4)]],
                    device float *timeBetweenJumps [[buffer(5)]],
                    device float *oldTime [[buffer(6)]],
                    device float *newTime [[buffer(7)]],
                    device simd_float3 *MTpoints [[buffer(8)]],
                    device int32_t *cellIDtoIndex [[buffer(9)]],
                    device int16_t *cellIDtoNMTs [[buffer(10)]],
                    device int32_t *indexToPoints [[buffer(11)]],
                    device int32_t *isAttachedIn [[buffer(12)]],
                    device int32_t *isAttachedOut [[buffer(13)]],
                    device float *randomSeedsIn [[buffer(14)]],
                    device float *randomSeedsOut [[buffer(15)]],
                    constant simulation_parameters & parameters [[buffer(16)]],
                    uint i [[thread_position_in_grid]],
                    uint l [[thread_position_in_threadgroup]]) {
    
    newTime[i] = oldTime[i] + parameters.deltat * parameters.cellRadius;
    
    int currentCellNumber = int(i / int(parameters.nBodies/parameters.nCells));
    
    int currentCellID = getCellID(positionsIn[i].x, positionsIn[i].y, positionsIn[i].z, parameters.cellRadius, parameters.cellsPerDimension, currentCellNumber);
    
    //Flag wether or not the particle should diffuse
    
    bool diffuseFlag = true;
    
    //Microtubule attachment/dettachment
    
    if (isAttachedIn[i] != -1){
        
        float randNumber = rand(int(randomSeedsIn[i]*100000), 0, 0);
        randomSeedsOut[i] = randNumber;
        
        //Probability that the particle detaches
        if (randNumber > wOFF){
            isAttachedOut[i] = -1;
        }else{
            //Check that the particle hasn't reached the end of the MT
            if (MTpoints[isAttachedIn[i] + 1].x == parameters.cellRadius &&
                MTpoints[isAttachedIn[i] + 1].y == parameters.cellRadius &&
                MTpoints[isAttachedIn[i] + 1].z == parameters.cellRadius){
                
                //If the particle reached the end of the MT, detach immediately
                isAttachedOut[i] = -1;
            }else{
                positionsOut[i] = MTpoints[isAttachedIn[i] + 1];
                isAttachedOut[i] = isAttachedIn[i] + 1;
                diffuseFlag = false;
            }
        }
    }else{
        
        float randNumber = rand(int(randomSeedsIn[i]*100000), 0, 0);
        randomSeedsOut[i] = randNumber;
        
        //Probability that the particle attaches
        if (randNumber > wON){
            
            //Check if it can attach to anything
            if (cellIDtoNMTs[currentCellID] != 0){
                
                int nMTs = cellIDtoNMTs[currentCellID];
                int chosenMT = int(rand(int(positionsIn[i].x*1000000), int(positionsIn[i].y*1000000), int(positionsIn[i].z*1000000))*nMTs);
                
                int MTindex = cellIDtoIndex[currentCellID];
                float3 MTpointOfAttachment = MTpoints[indexToPoints[MTindex + chosenMT]];
                positionsOut[i] = MTpointOfAttachment;
                
                isAttachedOut[i] = indexToPoints[MTindex + chosenMT];
                diffuseFlag = false;
            }
        }
    }
    
    // If the particle should diffuse (is not attached to a MT), diffuse
    
    if (diffuseFlag){
        
        float randNumber1 = rand(int(randomSeedsIn[i]*100000), 0, 0);
        float randNumber2 = rand(int(randNumber1*100000), 0, 0);
        float randNumber3 = rand(int(randNumber2*100000), int(randNumber1*100000), 0);
        randomSeedsOut[i] = randNumber3;
        
        float randNumberX = 2*rand(int(randNumber1*10000), int(positionsIn[i].y*10000), int(positionsIn[i].z*10000)) - 1;
        float randNumberY = 2*rand(int(positionsIn[i].y*10000), int(randNumber2*10000), int(positionsIn[i].z*10000)) - 1;
        float randNumberZ = 2*rand(int(positionsIn[i].y*10000), int(positionsIn[i].x*10000), int(randNumber3*10000)) - 1;
        
        positionsOut[i] = positionsIn[i] + 0.005*parameters.cellRadius*float3(randNumberX,randNumberY,randNumberZ);
        
        isAttachedOut[i] = -1;
    }
    
    float distance = sqrt(pow(positionsOut[i].x, 2) + pow(positionsOut[i].y, 2) + pow(positionsOut[i].z, 2));
    
    //Check if new point is inside cell radius
    if (distance >= parameters.cellRadius){
        
        updatedTimeLastJump[i] = newTime[i];
        timeBetweenJumps[i] = newTime[i] - timeLastJump[i];
        
        float4 point = randomSpherePoint(0.1 * parameters.cellRadius, int(positionsIn[i].x*100000), int(positionsIn[i].y*100000), int(positionsIn[i].z*100000));
        
        positionsOut[i].x = point.x;
        positionsOut[i].y = point.y;
        positionsOut[i].z = point.z;
        
        distance = point.w;
    }
    
    distances[i] = distance;
        
    //Check if new point is near a microtubule
    
    //int cellID = getCellID(positionsOut[i].x, positionsOut[i].y, positionsOut[i].z, parameters.cellRadius);
    
}

