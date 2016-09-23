//
//  BufferProvider.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 21..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import Metal
import Accelerate
import simd

open class BufferProvider: NSObject {
    
    let inflightBuffersCount: Int
    fileprivate var uniformBuffers: [MTLBuffer]
    fileprivate var availableBufferIndex: Int = 0
    
    init(device: MTLDevice, inflightBuffersCount: Int) {
        self.inflightBuffersCount = inflightBuffersCount
        let sizeOfUniformsBuffer = MemoryLayout<Float>.size * (float4x4.numberOfElements() * 2) + Light.size()
        uniformBuffers = [MTLBuffer]()
        for _ in 0..<inflightBuffersCount {
            let uniformBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
            uniformBuffers.append(uniformBuffer)
        }
        
    }
    
    func nextUniformsBuffer(_ projectionMatrix: float4x4, modelViewMatrix: float4x4, light: Light) -> MTLBuffer {
        let buffer = uniformBuffers[availableBufferIndex]
        let bufferPointer = buffer.contents()
        
        cblas_scopy(Int32(float4x4.numberOfElements()), modelViewMatrix.raw(), 1, bufferPointer.assumingMemoryBound(to: Float.self), 1)
        cblas_scopy(Int32(float4x4.numberOfElements()), projectionMatrix.raw(), 1, bufferPointer.assumingMemoryBound(to: Float.self).advanced(by: float4x4.numberOfElements()), 1)
        cblas_scopy(Int32(Light.count()), light.raw(), 1, bufferPointer.advanced(by: MemoryLayout<Float>.size * float4x4.numberOfElements() * 2).assumingMemoryBound(to: Float.self), 1)
        
        availableBufferIndex += 1
        if availableBufferIndex == inflightBuffersCount {
            availableBufferIndex = 0
        }
        
        return buffer
    }
}
