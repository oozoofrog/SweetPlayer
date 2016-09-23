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
    packed_float2 texCoord;
    packed_float3 normal;
};

struct VertexOut {
    float4 position [[position]];
    float3 fragmentPosition;
    float4 color;
    float2 texCoord;
    float3 normal;
};

struct Light {
    packed_float3 color;
    float ambientIntensity;
    packed_float3 direction;
    float diffuseIntensity;
    float shininess;
    float specularIntensity;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
    Light light;
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
    out.fragmentPosition = (mv_Matrix * float4(vertexIn.position, 1)).xyz;
    out.color = vertexIn.color;
    out.texCoord = vertexIn.texCoord;
    out.normal = (mv_Matrix * float4(vertexIn.normal, 0.0)).xyz;
    
    return out;
}

fragment float4 basic_fragment(
                              VertexOut interpolated [[stage_in]],
                               const device Uniforms& uniforms [[ buffer(1) ]],
                              texture2d<float> tex2d [[ texture(0) ]],
                               sampler sampler2d [[ sampler(0) ]]) {
    Light light = uniforms.light;
    float4 ambientColor = float4(light.color * light.ambientIntensity, 1);
    float diffuseFactor = max(0.0, dot(interpolated.normal, light.direction));
    float4 diffuseColor = float4(light.color * light.diffuseIntensity * diffuseFactor, 1.0);
    float3 eye = normalize(interpolated.fragmentPosition);
    float3 reflection = reflect(light.direction, interpolated.normal);
    float specularFactor = pow(max(0.0, dot(reflection, eye)), light.shininess);
    float4 specularColor = float4(light.color * light.specularIntensity * specularFactor, 1.0);
    float4 color = tex2d.sample(sampler2d, interpolated.texCoord);
    return color * (ambientColor + diffuseColor + specularColor);
}
