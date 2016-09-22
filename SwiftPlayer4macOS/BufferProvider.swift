//
//  BufferProvider.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 21..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import Metal

open class BufferProvider: NSObject {
    
    let inflightBuffersCount: Int
    fileprivate var uniformBuffers: [MTLBuffer]
    fileprivate var availableBufferIndex: Int = 0
    
    init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        self.inflightBuffersCount = inflightBuffersCount
        uniformBuffers = [MTLBuffer]()
        for _ in 0..<inflightBuffersCount {
            let uniformBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
            uniformBuffers.append(uniformBuffer)
        }
    }
    
    func nextUniformsBuffer(_ projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        let buffer = uniformBuffers[availableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer.advanced(by: MemoryLayout<Float>.size * Matrix4.numberOfElements()), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        
        availableBufferIndex += 1
        if availableBufferIndex == inflightBuffersCount {
            availableBufferIndex = 0
        }
        
        return buffer
    }
}
