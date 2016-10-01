//
//  PlayerView.swift
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 28..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import MetalKit
import AVFoundation

public class PlayerView: MTKView, MTKViewDelegate {
    
    private(set) public var player: Player?
    var movie: Movie?
    
    public var path: String?
    
    public var isFinished: Bool {
        return self.player?.isFinished ?? true
    }
    
    #if os(macOS) || os(osx)
    public var ratioLock: Bool = true
    #else
    private(set) var ratioLock: Bool = false
    #endif
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
    }
    
    
    #if os(iOS)
    #else
    public init(frame: NSRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    }
    #endif
    
    public func play(path: String = "", progressHandle: PlayerProgressHandle? = nil) -> Bool {
        if nil == self.player {
            self.path = path
            guard let player = Player(path: path, progressHandle: progressHandle) else {
                assertionFailure()
                return false
            }
            self.player = player
            Swift.print(String(describing: player))
            if let video = self.player?.video {
                guard let device = self.device else {
                    assertionFailure()
                    return false
                }
                self.colorPixelFormat = .bgra8Unorm
                self.clearColor = MTLClearColorMake(0, 0, 0, 1)
                
                self.currentRenderPassDescriptor?.colorAttachments[0].storeAction = .store
                self.currentRenderPassDescriptor?.colorAttachments[0].loadAction = .clear
                
                self.movie = Movie(device: device, pixelFormat: self.colorPixelFormat, colorMatrix: video.colorSpace.matrix, videoRatio: video.videoSize, screenRatio: self.bounds.size)
            }
        }
        self.delegate = self
        self.player?.start()
        return true
    }
    
    public func stop() {
        self.delegate = nil
        self.player?.stop()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if ratioLock, let videoSize = self.player?.videoSize {
            self.window?.aspectRatio = AVMakeRect(aspectRatio: videoSize, insideRect: CGRect(origin: CGPoint(), size: size)).size
        }
    }
    
    public func draw(in view: MTKView) {
        switch self.player?.requestVideoFrame() {
        case .video(let data)?:
            self.movie?.render(view: self, data: data)
        default:
            break
        }
    }
}
