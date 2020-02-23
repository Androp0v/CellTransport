//
//  Histogram.metal
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 14/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void histogramGPU(device float3 *positions [[buffer(0)]],
                    device float3 *histogram [[buffer(1)]],
                    uint i [[thread_position_in_grid]],
                    uint l [[thread_position_in_threadgroup]]) {

    
}
