//
//  MetalViewController.swift
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 19..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import AppKit
import MetalKit
import QuartzCore
import simd

protocol MetalViewControllerDelegate: class {
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval)
    func renderObjects(_ drawable: CAMetalDrawable)
}

open class MetalViewController: NSViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
//    var metalLayer: CAMetalLayer! = nil
    
    var textureLoader: MTKTextureLoader!
    
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    open var projectionMarix: float4x4!
    
    weak var delegate: MetalViewControllerDelegate?
    
    var mtkView: MTKView {
        return self.view as! MTKView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        projectionMarix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 45.0), aspectRatio: Float(self.view.bounds.width / self.view.bounds.height), nearZ: 0.01, farZ: 100)
        
        device = MTLCreateSystemDefaultDevice()
        self.textureLoader = MTKTextureLoader(device: device)
  
        self.mtkView.device = self.device
        self.mtkView.colorPixelFormat = .bgra8Unorm
        self.mtkView.delegate = self
        self.mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        self.commandQueue = device.makeCommandQueue()
        let defaultLibrary = try! device.makeDefaultLibrary(bundle: Bundle.main)
        let fragment = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertex = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertex
        pipelineStateDescriptor.fragmentFunction = fragment

        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMarix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 45.0), aspectRatio: Float(self.view.bounds.width / self.view.bounds.height), nearZ: 0.01, farZ: 100)
    }
    
    public func draw(in view: MTKView) {
        if let drawable = view.currentDrawable {
            self.render(drawable: drawable)
        }
    }
    
    func render(drawable: CAMetalDrawable) {
        self.delegate?.renderObjects(drawable)
    }
    
}
