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
    var bufferProvider: BufferProvider
    
    var position: Points = Points()
    var rotation: Points = Points()
    var scale: Float = 1.0
    
    var texture: MTLTexture
    lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState {
        let pSamplerDescriptor: MTLSamplerDescriptor = MTLSamplerDescriptor()
        pSamplerDescriptor.minFilter = .nearest
        pSamplerDescriptor.magFilter = .nearest
        pSamplerDescriptor.mipFilter = .nearest
        pSamplerDescriptor.maxAnisotropy = 1
        pSamplerDescriptor.sAddressMode = .clampToEdge
        pSamplerDescriptor.tAddressMode = .clampToEdge
        pSamplerDescriptor.rAddressMode = .clampToEdge
        pSamplerDescriptor.normalizedCoordinates = true
        pSamplerDescriptor.lodMinClamp = 0
        pSamplerDescriptor.lodMaxClamp = FLT_MAX
        return device.makeSamplerState(descriptor: pSamplerDescriptor)
    }
    
    init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture) {
        let vertexData = vertices.reduce([Float]()) { (floats, vertex) -> [Float] in
            return floats + vertex.floatBuffer
        }
        vertexCount = vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count, options: [])
        self.name = name
        self.device = device
        self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2)
        self.texture = texture
    }
    
    func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix projection: Matrix4, clearColor: MTLClearColor?) {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor ?? MTLClearColor(red: 0, green: 104 / 255.0, blue: 5 / 255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        renderEncoder.setCullMode(.front)
        let nodeModelMatrix = self.modelMatrix
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        uniformBuffer = bufferProvider.nextUniformsBuffer(projection, modelViewMatrix: nodeModelMatrix)
        renderEncoder.setVertexBuffer(uniformBuffer!, offset: 0, at: 1)
        renderEncoder.setFragmentTexture(texture, at: 0)
        renderEncoder.setFragmentSamplerState(self.samplerState, at: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount / 3)
        renderEncoder.endEncoding()
        
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
    
    var time: CFTimeInterval = 0.0
    func update(withDelta delta: CFTimeInterval) {
        time += delta
    }
}
