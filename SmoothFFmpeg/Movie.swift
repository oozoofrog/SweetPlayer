//
//  Movie.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 23..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import MetalKit
import simd
import Accelerate
import AVFoundation

public class Movie {
    
    let device: MTLDevice
    
    let vertices: [Float] = [-1, 1, 0, 0,
                             -1, -1, 0, 1,
                             1, -1, 1, 1,
                             -1, 1, 0, 0,
                             1, -1, 1, 1,
                             1, 1, 1, 0]
    

    let vertexBuffer: MTLBuffer
    let convolutionBuffer: MTLBuffer
    let decreaseBuffer: MTLBuffer
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    //let sample: MTLSamplerState
    
    fileprivate var videoRatio: CGSize
    var screenRatio: CGSize {
        willSet {
            let textureRatio = AVMakeRect(aspectRatio: videoRatio, insideRect: CGRect(origin: CGPoint(), size: newValue))
            self.modelMatrix = float4x4.makeScale(1, Float(textureRatio.height / newValue.height), 1)
        }
    }
    
    var modelMatrix: float4x4
    
    public init(device: MTLDevice, pixelFormat: MTLPixelFormat, colorMatrix: ColorMatrix, videoRatio: CGSize, screenRatio: CGSize) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.size * vertices.count, options: [])
        
        convolutionBuffer = device.makeBuffer(bytes: colorMatrix.kernel, length: MemoryLayout<Float>.size * 16, options: [])
        decreaseBuffer = device.makeBuffer(bytes: ColorMatrix.yuvK, length: MemoryLayout<Float>.size * 4, options: [])
        let pipelineStateDesc = MTLRenderPipelineDescriptor()
        #if os(iOS)
        let library = device.newDefaultLibrary()!
        #else
        let library = try! device.makeDefaultLibrary(bundle: Bundle(for: Player.self))
        #endif
        pipelineStateDesc.vertexFunction = library.makeFunction(name: "movieVertex")
        pipelineStateDesc.fragmentFunction = library.makeFunction(name: "movieFragment")
        pipelineStateDesc.colorAttachments[0].pixelFormat = pixelFormat

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDesc)
        
        self.videoRatio = videoRatio
        self.screenRatio = screenRatio
        
        let textureRatio = AVMakeRect(aspectRatio: videoRatio, insideRect: CGRect(origin: CGPoint(), size: screenRatio))
        self.modelMatrix = float4x4.makeScale(1, Float(textureRatio.height / screenRatio.height), 1)
    }
    
    public func render(view: MTKView, data: VideoData, clearColor: MTLClearColor = MTLClearColorMake(0, 0, 0, 1)) {
        guard let drawable = view.currentDrawable, let renderPassDesc = view.currentRenderPassDescriptor else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc)
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        let modelMatrixBuffer = self.device.makeBuffer(bytes: self.modelMatrix.raw(), length: MemoryLayout<Float>.size * float4x4.numberOfElements(), options: [])
        renderEncoder.setVertexBuffer(modelMatrixBuffer, offset: 0, at: 1)
        let textures = data.textures(device: device)
        renderEncoder.setFragmentTexture(textures.y.texture, at: 0)
        renderEncoder.setFragmentTexture(textures.u.texture, at: 1)
        renderEncoder.setFragmentTexture(textures.v.texture, at: 2)
        renderEncoder.setFragmentBuffer(convolutionBuffer, offset: 0, at: 1)
        renderEncoder.setFragmentBuffer(decreaseBuffer, offset: 0, at: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}


struct K {
    var r, g, b: Float
    var cbk: Float {
        return b / g
    }
    var crk: Float {
        return r / g
    }
}


public struct ColorMatrix {
    
    static let yuvK: [Float] = [-16 / 255.0, -0.5, -0.5, 0]
    
    static let bt601: ColorMatrix = ColorMatrix(k: K(r: 0.299, g: 0.587, b: 0.114))
    static let bt709: ColorMatrix = ColorMatrix(k: K(r: 0.2126, g: 0.587, b: 0.0722))
    static let bt2020: ColorMatrix = ColorMatrix(k: K(r: 0.2627, g: 0.587, b: 0.0593))
    
    static let yk: Float = 255 / 219
    static let cbk: Float = 255 / 112 * 0.886
    static let crk: Float = 255 / 112 * 0.701
    
    let k: K
    public var kernel: [Float] {
        return [ColorMatrix.yk, 0, ColorMatrix.crk, 0,
                ColorMatrix.yk, -ColorMatrix.cbk * k.cbk, -ColorMatrix.crk * k.crk, 0,
                ColorMatrix.yk, ColorMatrix.cbk, 0, 0,
                0, 0, 0, 0]
    }
}


struct LuminanceDataTextures {
    let desc: MTLTextureDescriptor
    let texture: MTLTexture
    init(device: MTLDevice, width: Int, height: Int, length: Int, data: Data) {
        desc = MTLTextureDescriptor()
        desc.width = width
        desc.height = height
        desc.pixelFormat = .r8Unorm
        let buffer: UnsafeRawPointer = data.withUnsafeBytes({ (ptr) -> UnsafeRawPointer in
            return UnsafeRawPointer(ptr)
        })
        self.texture = device.makeTexture(descriptor: desc)
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: buffer, bytesPerRow: length)
    }
}

struct YUVData {
    let y: LuminanceDataTextures
    let u: LuminanceDataTextures
    let v: LuminanceDataTextures
}

extension VideoData {
    func textures(device: MTLDevice) -> YUVData {
        let w = Int(self.w)
        let h = Int(self.h)
        return YUVData(y: LuminanceDataTextures(device: device, width: w, height: h, length: Int(self.lumaLength), data: self.y),
                       u: LuminanceDataTextures(device: device, width: w / 2, height: h / 2, length: Int(self.chromaLength), data: self.u),
                       v: LuminanceDataTextures(device: device, width: w / 2, height: h / 2, length: Int(self.chromaLength), data: self.v))
    }
}
