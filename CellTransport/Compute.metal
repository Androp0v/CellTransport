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

// Generate a random float in the range [0.0f, 1.0f] using x, y, and z (based on the xor128 algorithm)
float rand(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

//Generate random sphere points
float4 randomSpherePoint(float radius, int x, int y, int z){
    /*float theta = 2*M_PI_F*rand(x, y, z);
    float phi = 2*M_PI_F*acos(1-2*rand(z, x, y));
    
    float xsphere = radius*sin(phi)*cos(theta);
    float ysphere = radius*sin(phi)*sin(theta);
    float zsphere = radius*cos(phi);*/
    
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

kernel void compute(device float3 *positionsIn [[buffer(0)]],
                    device float3 *positionsOut [[buffer(1)]],
                    device float *distances [[buffer(2)]],
                    device float *timeLastJump [[buffer(3)]],
                    device float *updatedTimeLastJump [[buffer(4)]],
                    device float *timeBetweenJumps [[buffer(5)]],
                    device float *oldTime [[buffer(6)]],
                    device float *newTime [[buffer(7)]],
                    uint i [[thread_position_in_grid]],
                    uint l [[thread_position_in_threadgroup]]) {
    
    newTime[i] = oldTime[i] + deltaT*cellRadius;
        
    float randNumberX = 2*rand(int(positionsIn[i].x*10000), int(positionsIn[i].y*10000), int(positionsIn[i].z*10000)) - 1.0;
    float randNumberY = 2*rand(int(positionsIn[i].y*10000), int(positionsIn[i].z*10000), int(positionsIn[i].z*10000)) - 1.0;
    float randNumberZ = 2*rand(int(positionsIn[i].y*10000), int(positionsIn[i].y*10000), int(positionsIn[i].z*10000)) - 1.0;
    
    positionsOut[i] = positionsIn[i]  + 0.01*cellRadius*float3(randNumberX,randNumberY,randNumberZ);
    
    float distance = sqrt(pow(positionsOut[i].x, 2) + pow(positionsOut[i].y, 2) + pow(positionsOut[i].z, 2));
    
    //TO-DO Fix
    float sum = 0;
    for (int j = 0; j < 16; j++){
        sum += positionsIn[j].x;
    }
    //TO-DO End fix
    
    if (distance >= cellRadius){
        
        updatedTimeLastJump[i] = newTime[i];
        timeBetweenJumps[i] = newTime[i] - timeLastJump[i];
        
        float4 point = randomSpherePoint(0.1 * cellRadius, int(positionsIn[i].x*100000), int(positionsIn[i].y*100000), int(positionsIn[i].z*100000));
        
        positionsOut[i].x = point.x;
        positionsOut[i].y = point.y;
        positionsOut[i].z = point.z;
        
        distance = point.w;
    }
    
    distances[i] = distance + 0.000000001*sum; //TO-DO Fix
    
}

