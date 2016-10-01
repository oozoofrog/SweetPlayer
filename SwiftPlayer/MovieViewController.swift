//
//  MovieViewController.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 23..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import UIKit
import MetalKit
class MovieViewController: UIViewController, MTKViewDelegate {
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
        self.mtkView.colorPixelFormat = .rgba8Uint
        let frameRate = Int(self.player?.fps ?? 0)
        self.mtkView.preferredFramesPerSecond = frameRate == 0 ? 10 : frameRate
        self.mtkView.clearColor = MTLClearColorMake(1, 0, 0, 1)
        self.mtkView.delegate = self
        
        self.movie = Movie(device: self.mtkView.device!, pixelFormat: self.mtkView.colorPixelFormat, colorMatrix: video.colorSpace.matrix, videoRatio: video.videoSize, screenRatio: self.view.bounds.size)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.movie.screenRatio = size
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
}
