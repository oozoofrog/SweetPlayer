//
//  ViewController.swift
//  SwiftPlayer4macOS
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

    var device: MTLDevice?
    var metalLayer: CAMetalLayer?
    var buffer: MTLBuffer?
    var pipelineState: MTLRenderPipelineState?
    var commandQueue: MTLCommandQueue?
    var displayLink: CVDisplayLink?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.device = MTLCreateSystemDefaultDevice()
        let layer = CAMetalLayer()
        self.metalLayer = layer
        self.metalLayer?.device = self.device
        self.metalLayer?.pixelFormat = .bgra8Unorm
        self.metalLayer?.framebufferOnly = true
        self.metalLayer?.frame = self.view.bounds
        
        self.view.layer = self.metalLayer
        
        let vertexData: [Float] = [0.0, 1.0, 0.0, -1.0, -1.0, 0.0, 1.0, -1.0, 0.0]
        self.buffer = device?.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count, options: [])
        
        let library = try! device?.makeDefaultLibrary(bundle: Bundle.main)
        let fragment = library?.makeFunction(name: "basic_fragment")
        let vertex = library?.makeFunction(name: "basic_vertex")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.fragmentFunction = fragment
        pipelineDescriptor.vertexFunction = vertex
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        self.pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        self.commandQueue = device?.makeCommandQueue()
        
        var ret = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard ret == kCVReturnSuccess else {
            return
        }
        if let link = self.displayLink {
            CVDisplayLinkSetOutputHandler(link, { (link, inNow, inOutput, flagsIn, flagsOut) -> CVReturn in
                autoreleasepool(invoking: { () -> Void in
                    self.render()
                })
                return kCVReturnSuccess
            })
        }
    }
    
    func render() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = self.metalLayer?.nextDrawable()?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 104.0 / 255.0, 5.0 / 255.0, 1.0)
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderEncoderOpt = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoderOpt?.setRenderPipelineState(pipelineState!)
        renderEncoderOpt?.setVertexBuffer(self.buffer, offset: 0, at: 0)
        renderEncoderOpt?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoderOpt?.endEncoding()
        
        commandBuffer?.present((self.metalLayer?.nextDrawable())!)
        commandBuffer?.commit()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        CVDisplayLinkStart(self.displayLink!)
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        self.view.layer?.frame = self.view.bounds
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
}

