//
//  Shaders.metal
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut basic_vertex(
                           const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms& uniforms [[ buffer(1) ]],
                           unsigned int vid [[ vertex_id ]]
) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn vertexIn = vertex_array[vid];
    
    VertexOut out;
    out.position = proj_Matrix * mv_Matrix * float4(vertexIn.position, 1);
    out.color = vertexIn.color;
    
    return out;
}

fragment half4 basic_fragment(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}
