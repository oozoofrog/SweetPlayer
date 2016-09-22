//
//  MetalViewController.swift
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 19..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import AppKit
import Metal
import QuartzCore

extension CVTimeStamp {
    var timeInterval: CFTimeInterval {
        return CFTimeInterval(self.videoTime) / CFTimeInterval(self.videoTimeScale)
    }
}

protocol MetalViewControllerDelegate: class {
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval)
    func renderObjects(_ drawable: CAMetalDrawable)
}

open class MetalViewController: NSViewController {
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CVDisplayLink? = nil
    open var projectionMarix: Matrix4!
    var lastFrameTimestamp: CFTimeInterval = 0
    
    weak var delegate: MetalViewControllerDelegate?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        projectionMarix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 45.0), aspectRatio: Float(self.view.bounds.width / self.view.bounds.height), nearZ: 0.01, farZ: 100)
        
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = self.device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        self.view.layer = metalLayer
        
        self.commandQueue = device.makeCommandQueue()
        let defaultLibrary = try! device.makeDefaultLibrary(bundle: Bundle.main)
        let fragment = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertex = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertex
        pipelineStateDescriptor.fragmentFunction = fragment

        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        CVDisplayLinkCreateWithActiveCGDisplays(&self.timer)
        
        CVDisplayLinkSetOutputHandler(self.timer!, { (link, inTime, outTime, inOpts, outOpts) -> CVReturn in
            self.newFrame(self.timer!, inTime: inTime.pointee)
            return kCVReturnSuccess
        })
        
        CVDisplayLinkStart(self.timer!)
    }
    
    open override func viewWillLayout() {
        super.viewWillLayout()
        if let window = view.window {
            let scale = window.screen?.backingScaleFactor ?? 0.0
            let layerSize = self.view.bounds.size
            metalLayer.frame = self.view.bounds
            metalLayer.drawableSize = layerSize.applying(CGAffineTransform(scaleX: scale, y: scale))
        }
        projectionMarix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 45.0), aspectRatio: Float(self.view.bounds.width / self.view.bounds.height), nearZ: 0.01, farZ: 100)
    }
    
    func render() {
        if let drawable = metalLayer.nextDrawable() {
            self.delegate?.renderObjects(drawable)
        }
    }
    
    func newFrame(_ displayLink: CVDisplayLink, inTime: CVTimeStamp) {
        let interval = inTime.timeInterval
        if 0.0 == self.lastFrameTimestamp {
            lastFrameTimestamp = interval
        }
        let elapsed: CFTimeInterval = interval - lastFrameTimestamp
        lastFrameTimestamp = interval
        
        gameloop(elapsed)
    }
    
    func gameloop(_ timeSinceLastUpdate: CFTimeInterval) {
        self.delegate?.updateLogic(timeSinceLastUpdate)
        autoreleasepool {
            self.render()
        }
    }
}
