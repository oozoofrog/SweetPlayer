//
//  Nod.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import Metal
import QuartzCore
import Accelerate

struct Points {
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
}

class Node {
    
    let name: String
    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    var uniformBuffer: MTLBuffer?
    let device: MTLDevice
    
    var position: Points = Points()
    var rotation: Points = Points()
    var scale: Float = 1.0
    
    init(name: String, vertices: Array<Vertex>, device: MTLDevice) {
        let vertexData = vertices.reduce([Float]()) { (floats, vertex) -> [Float] in
            return floats + vertex.floatBuffer
        }
        vertexCount = vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count, options: [])
        self.name = name
        self.device = device
    }
    
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, projectionMatrix projection: Matrix4, clearColor: MTLClearColor?) {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor ?? MTLClearColor(red: 0, green: 104 / 255.0, blue: 5 / 255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoderOpt = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoderOpt.setRenderPipelineState(pipelineState)
        renderEncoderOpt.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        let nodeModelMatrix = self.modelMatrix
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2, options: [])
        
        let bufferPointer = uniformBuffer?.contents()
        cblas_scopy(Int32(Matrix4.numberOfElements()), nodeModelMatrix.raw().assumingMemoryBound(to: Float.self), 1, bufferPointer?.assumingMemoryBound(to: Float.self), 1)
        cblas_scopy(Int32(Matrix4.numberOfElements()), projection.raw().assumingMemoryBound(to: Float.self), 1, bufferPointer?.assumingMemoryBound(to: Float.self).advanced(by: Matrix4.numberOfElements()), 1)
        renderEncoderOpt.setVertexBuffer(uniformBuffer!, offset: 0, at: 1)
        renderEncoderOpt.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        renderEncoderOpt.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    var modelMatrix: Matrix4 {
        let matrix = Matrix4()
        matrix?.translate(self.position.x, y: self.position.y, z: self.position.z)
        matrix?.rotateAroundX(self.rotation.x, y: self.rotation.y, z: self.rotation.z)
        matrix?.scale(scale, y: scale, z: scale)
        return matrix!
    }
}
