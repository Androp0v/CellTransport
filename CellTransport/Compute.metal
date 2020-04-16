//
//  Compute.metal
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define deltaT 0.00001
#define cellRadius 14000
#define cellsPerDimension 1000

// Get CellID of a position in x,y,z coordinates
int getCellID(float x, float y, float z){
    
    int cellID = 0;
    cellID += cellsPerDimension*cellsPerDimension * floor(cellsPerDimension * ((z+cellRadius/2)/cellRadius));
    cellID += cellsPerDimension * floor(cellsPerDimension * ((y+cellRadius/2)/cellRadius));
    cellID += floor(cellsPerDimension * ((x+cellRadius/2)/cellRadius));
    
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
};

kernel void compute(device float3 *positionsIn [[buffer(0)]],
                    device float3 *positionsOut [[buffer(1)]],
                    device float *distances [[buffer(2)]],
                    device float *timeLastJump [[buffer(3)]],
                    device float *updatedTimeLastJump [[buffer(4)]],
                    device float *timeBetweenJumps [[buffer(5)]],
                    device float *oldTime [[buffer(6)]],
                    device float *newTime [[buffer(7)]],
                    constant simulation_parameters & parameters [[buffer(8)]],
                    uint i [[thread_position_in_grid]],
                    uint l [[thread_position_in_threadgroup]]) {
    
    newTime[i] = oldTime[i] + parameters.deltat*cellRadius;
        
    float randNumberX = 2*rand(int(positionsIn[i].x*10000), int(positionsIn[i].y*10000), int(positionsIn[i].z*10000)) - 1.0;
    float randNumberY = 2*rand(int(positionsIn[i].y*10000), int(positionsIn[i].z*10000), int(positionsIn[i].z*10000)) - 1.0;
    float randNumberZ = 2*rand(int(positionsIn[i].y*10000), int(positionsIn[i].y*10000), int(positionsIn[i].z*10000)) - 1.0;
    
    positionsOut[i] = positionsIn[i]  + 0.01*cellRadius*float3(randNumberX,randNumberY,randNumberZ);
    
    float distance = sqrt(pow(positionsOut[i].x, 2) + pow(positionsOut[i].y, 2) + pow(positionsOut[i].z, 2));
    
    //Check if new point is inside cell radius
    if (distance >= cellRadius){
        
        updatedTimeLastJump[i] = newTime[i];
        timeBetweenJumps[i] = newTime[i] - timeLastJump[i];
        
        float4 point = randomSpherePoint(0.1 * cellRadius, int(positionsIn[i].x*100000), int(positionsIn[i].y*100000), int(positionsIn[i].z*100000));
        
        positionsOut[i].x = point.x;
        positionsOut[i].y = point.y;
        positionsOut[i].z = point.z;
        
        distance = point.w;
    }
    
    //Check if new point is near a microtubule
    
    int cellID = getCellID(positionsOut[i].x, positionsOut[i].y, positionsOut[i].z);
    
    distances[i] = distance;
    
}

