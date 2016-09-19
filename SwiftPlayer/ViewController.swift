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

class ViewController: UIViewController {
    
    var path: String? = nil
    var device: MTLDevice?
    var metalLayer: CAMetalLayer?
    var vertexBuffer: MTLBuffer?
    var pipelineState: MTLRenderPipelineState?
    var commandQueue: MTLCommandQueue?
    
    var displayLink: CADisplayLink?
    
    let vertexData: [Float] = [0.0, 1.0, 0.0, -1.0, -1.0, 0.0, 1.0, -1.0, 0.0]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        self.device = device
        
        let layer = CAMetalLayer()
        self.metalLayer = layer
        self.metalLayer?.device = self.device
        self.metalLayer?.pixelFormat = .bgra8Unorm
        self.metalLayer?.framebufferOnly = true
        self.metalLayer?.frame = self.view.bounds
        self.view.layer.addSublayer(layer)
        
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        
        let defaultLibrary = device.newDefaultLibrary()
        let fragment = defaultLibrary?.makeFunction(name: "basic_fragment")
        let vertex = defaultLibrary?.makeFunction(name: "basic_vertex")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.fragmentFunction = fragment
        pipelineDescriptor.vertexFunction = vertex
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try self.pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print(error.localizedDescription)
            return
        }
        
        self.commandQueue = device.makeCommandQueue()
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayRefresh(link:)))
        self.displayLink?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.metalLayer?.frame = self.view.bounds
    }
    
    func displayRefresh(link: CADisplayLink) {
        autoreleasepool { () -> Void in
            self.render()
        }
    }
    
    func render() {
        
    }
}

