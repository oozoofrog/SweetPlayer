//
//  Movie.metal
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 23..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 movieVertex(const device packed_float2* in [[ buffer(0) ]],
                          unsigned int vid [[ vertex_id ]]) {
    
    return float4(in[vid], 0, 1);
}

fragment float4 movieFragment(float4 interpolated [[stage_in]]) {
    
    return float4(1, 1, 1, 1);
}
