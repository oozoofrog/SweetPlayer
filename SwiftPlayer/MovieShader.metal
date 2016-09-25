//
//  Movie.metal
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 23..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float2 position;
    packed_float2 texCoord;
};

struct VertexOut {
    float4 position [[ position ]];
    float2 texCoord;
};

vertex VertexOut movieVertex(const device VertexIn* in [[ buffer(0) ]],
                             const device float4x4& mvMatrix [[ buffer(1) ]],
                          unsigned int vid [[ vertex_id ]]) {
    VertexIn vin = in[vid];
    VertexOut out;
    out.position = mvMatrix * float4(vin.position, 0, 1);
    out.texCoord = vin.texCoord;
    return out;
}

constexpr sampler sampler2d(coord::normalized,
                            address::clamp_to_zero,
                            filter::linear);

fragment float4 movieFragment(VertexOut interpolated [[stage_in]],
                              texture2d<float> yt [[ texture(0) ]],
                              texture2d<float> ut [[ texture(1) ]],
                              texture2d<float> vt [[ texture(2) ]],
                              const device float4x4& convolution [[ buffer(1) ]],
                              const device float4& yuvk [[ buffer(2) ]]) {
    
    float y = yt.sample(sampler2d, interpolated.texCoord).x;
    float u = ut.sample(sampler2d, interpolated.texCoord).x;
    float v = vt.sample(sampler2d, interpolated.texCoord).x;
    float4 yuv = float4(y, u, v, 0) + yuvk;
    float4 rgb = yuv * convolution;
    return float4(rgb.rgb, 1);
}
