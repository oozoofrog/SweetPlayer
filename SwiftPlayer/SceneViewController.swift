//
//  ViewController.swift
//  SwiftPlayer
//
//  Created by Kwanghoon Choi on 2016. 8. 29..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import simd

class SceneViewController: UIViewController, MTKViewDelegate {

    var path: String?
    
    var mtkView: MTKView {
        return self.view as! MTKView
    }
    
    var device: MTLDevice? = MTLCreateSystemDefaultDevice()
    var commandQueue: MTLCommandQueue?
    var renderpipelineState: MTLRenderPipelineState?
    
    var vertexBuffer: MTLBuffer?
    let triangle: [Float] = [0, 1, -1, -1, 1, -1]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mtkView.device = self.device
        self.mtkView.colorPixelFormat = .bgra8Unorm
        self.mtkView.clearColor = MTLClearColorMake(1, 0, 0, 1)
        self.mtkView.delegate = self
        self.mtkView.framebufferOnly = true
        
        self.commandQueue = self.device?.makeCommandQueue()
        let library = self.device?.newDefaultLibrary()
        let vertex = library?.makeFunction(name: "movieVertex")
        let fragment = library?.makeFunction(name: "movieFragment")
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertex
        desc.fragmentFunction = fragment
        desc.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat
        renderpipelineState = try! self.device?.makeRenderPipelineState(descriptor: desc)
        
        vertexBuffer = device?.makeBuffer(bytes: triangle, length: MemoryLayout<Float>.size * triangle.count, options: [])
    }

    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        let renderPassDesc = MTLRenderPassDescriptor()
        
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPassDesc.colorAttachments[0].storeAction = .store
        renderPassDesc.colorAttachments[0].loadAction = .clear
        renderPassDesc.colorAttachments[0].texture = view.currentDrawable?.texture
        
        let commandBuffer = self.commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesc)
        renderEncoder?.setRenderPipelineState(self.renderpipelineState!)
        renderEncoder?.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
}

