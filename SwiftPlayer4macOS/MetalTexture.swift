//
//  MetalTexture.swift
//  MetalKernelsPG
//
//  Created by Andrew K. on 10/20/14.
//  Copyright (c) 2014 Andrew K. All rights reserved.
//

import Metal
import MetalKit
import AppKit

class MetalTexture: NSObject {
    
    var texture: MTLTexture!
    var target: MTLTextureType!
    var width: Int!
    var height: Int!
    var depth: Int!
    var format: MTLPixelFormat!
    var hasAlpha: Bool!
    var path: String!
    var isMipmaped: Bool!
    let bytesPerPixel:Int! = 4
    let bitsPerComponent:Int! = 8
    
    //MARK: - Creation
    init(resourceName: String,ext: String, mipmaped:Bool){
        
        path = Bundle.main.path(forResource: resourceName, ofType: ext)
        width    = 0
        height   = 0
        depth    = 1
        format   = MTLPixelFormat.rgba8Unorm
        target   = MTLTextureType.type2D
        texture  = nil
        isMipmaped = mipmaped
        
        super.init()
    }
    
    func loadTexture(device: MTLDevice, commandQ: MTLCommandQueue, flip: Bool){
        #if os(iOS)
            let image = UIImage(contentsOfFile: path)!.CGImage!
        #else
            let image = NSImage(contentsOfFile: path)!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        #endif
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        width = image.width
        height = image.height
        
        let rowBytes = width * bytesPerPixel
        
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let bounds = CGRect(x: 0, y: 0, width: Int(width), height: Int(height))
        context.clear(bounds)
        
        if flip == false{
            context.translateBy(x: 0, y: CGFloat(self.height))
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        context.draw(image, in: bounds)
        
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(width), height: Int(height), mipmapped: isMipmaped)
        target = texDescriptor.textureType
        texture = device.makeTexture(descriptor: texDescriptor)
        
        let pixelsData = context.data
        let region = MTLRegionMake2D(0, 0, Int(width), Int(height))
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelsData!, bytesPerRow: Int(rowBytes))
        
        if (isMipmaped == true){
            generateMipMapLayersUsingSystemFunc(texture, device: device, commandQ: commandQ, block: { (buffer) -> Void in
                print("mips generated")
            })
        }
        
        print("mipCount:\(texture.mipmapLevelCount)")
    }
    
    
    
    class func textureCopy(source:MTLTexture,device: MTLDevice, mipmaped: Bool) -> MTLTexture {
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(source.width), height: Int(source.height), mipmapped: mipmaped)
        let copyTexture = device.makeTexture(descriptor: texDescriptor)
        
        
        let region = MTLRegionMake2D(0, 0, Int(source.width), Int(source.height))
        let pixelsData = malloc(source.width * source.height * 4)
        source.getBytes(pixelsData!, bytesPerRow: Int(source.width) * 4, from: region, mipmapLevel: 0)
        copyTexture.replace(region: region, mipmapLevel: 0, withBytes: pixelsData!, bytesPerRow: Int(source.width) * 4)
        return copyTexture
    }
    
    class func copyMipLayer(source:MTLTexture, destination:MTLTexture, mipLvl: Int){
        let q = Int(powf(2, Float(mipLvl)))
        let mipmapedWidth = max(Int(source.width)/q,1)
        let mipmapedHeight = max(Int(source.height)/q,1)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pixelsData = malloc(mipmapedHeight * mipmapedWidth * 4)
        source.getBytes(pixelsData!, bytesPerRow: mipmapedWidth * 4, from: region, mipmapLevel: mipLvl)
        destination.replace(region: region, mipmapLevel: mipLvl, withBytes: pixelsData!, bytesPerRow: mipmapedWidth * 4)
        free(pixelsData)
    }
    
    //MARK: - Generating UIImage from texture mip layers
    #if os(iOS)
    func image(mipLevel: Int) -> UIImage{
        
        let p = bytesForMipLevel(mipLevel: mipLevel)
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(width / q,1)
        let mipmapedHeight = max(height / q,1)
        let rowBytes = mipmapedWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: p, width: mipmapedWidth, height: mipmapedHeight, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let imgRef = context.makeImage()
        let image = UIImage(CGImage: imgRef!)
        return image
    }
    
    func image() -> UIImage{
        return image(mipLevel: 0)
    }
    #else
    func image(mipLevel: Int) -> NSImage{
        
        let p = bytesForMipLevel(mipLevel: mipLevel)
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(width / q,1)
        let mipmapedHeight = max(height / q,1)
        let rowBytes = mipmapedWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: p, width: mipmapedWidth, height: mipmapedHeight, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let imgRef = context.makeImage()!
        let image = NSImage(cgImage: imgRef, size: NSSize(width: imgRef.width, height: imgRef.height))
        return image
    }
    
    func image() -> NSImage{
        return image(mipLevel: 0)
    }
    #endif
 
    
    //MARK: - Getting raw bytes from texture mip layers
    func bytesForMipLevel(mipLevel: Int) -> UnsafeMutableRawPointer{
        let q = Int(powf(2, Float(mipLevel)))
        let mipmapedWidth = max(Int(width) / q,1)
        let mipmapedHeight = max(Int(height) / q,1)
        
        let rowBytes = Int(mipmapedWidth * 4)
        
        let region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
        let pointer = malloc(rowBytes * mipmapedHeight)
        texture.getBytes(pointer!, bytesPerRow: rowBytes, from: region, mipmapLevel: mipLevel)
        return pointer!
    }
    
    func bytes() -> UnsafeMutableRawPointer{
        return bytesForMipLevel(mipLevel: 0)
    }
    
    func generateMipMapLayersUsingSystemFunc(_ texture: MTLTexture, device: MTLDevice, commandQ: MTLCommandQueue,block: @escaping MTLCommandBufferHandler){
        
        let commandBuffer = commandQ.makeCommandBuffer()
        
        commandBuffer.addCompletedHandler(block)
        
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        
        blitCommandEncoder.generateMipmaps(for: texture)
        blitCommandEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
}
