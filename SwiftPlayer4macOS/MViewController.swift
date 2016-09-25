//
//  MViewController.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 23..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import AppKit
import MetalKit
import AVFoundation

extension Data {
    func chars() -> [UInt8] {
        var chars: [UInt8] = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &chars, count: self.count)
        return chars
    }
}

public class MViewController: NSViewController, MTKViewDelegate {
    
    var player: Player?
    
    
    @IBOutlet var mtkView: MTKView!
    var movie: Movie!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let path = Bundle.main.path(forResource: "sample", ofType: "mp4") else {
            assertionFailure()
            return
        }
        guard let player = Player(path: path) else {
            assertionFailure()
            return
        }
        
        self.player = player
        
        guard let video = self.player?.video else {
            return
        }
        
        self.mtkView.device = MTLCreateSystemDefaultDevice()
        self.mtkView.colorPixelFormat = .bgra8Unorm_srgb
        let frameRate = Int(self.player?.fps ?? 0)
        self.mtkView.preferredFramesPerSecond = frameRate == 0 ? 10 : frameRate
        self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        self.mtkView.delegate = self
        self.mtkView.currentRenderPassDescriptor?.colorAttachments[0].storeAction = .store
        self.mtkView.currentRenderPassDescriptor?.colorAttachments[0].loadAction = .clear
        
        self.movie = Movie(device: self.mtkView.device!, pixelFormat: self.mtkView.colorPixelFormat, colorMatrix: video.colorSpace.matrix, videoRatio: video.videoSize, screenRatio: self.view.bounds.size)
        self.view.window?.aspectRatio = AVMakeRect(aspectRatio: self.player?.videoSize ?? view.bounds.size, insideRect: CGRect(origin: CGPoint(), size: view.bounds.size)).size
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        
        var link: CVDisplayLink?
        guard CVDisplayLinkCreateWithActiveCGDisplays(&link) == kCVReturnSuccess else {
            return
        }
        guard let display = link else {
            return
        }
        var period = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(display)
        
        var rate = Double(period.timeScale) / Double(period.timeValue)
        var ratef = round(rate)
        print(ratef)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.view.window?.aspectRatio = AVMakeRect(aspectRatio: self.player?.videoSize ?? size, insideRect: CGRect(origin: CGPoint(), size: size)).size
    }
    public func draw(in view: MTKView) {
        var data: VideoData?
        loop: while true {
            switch self.player?.decodeFrame() {
            case .video(let vd)?:
                data = vd
                break loop
            case .finish?:
                break loop
            default:
                break
            }
        }
        guard let videoData = data else {
            return
        }
        self.movie.render(view: view, data: videoData)
    }
    
    deinit {
        avformat_network_deinit()
    }
}
