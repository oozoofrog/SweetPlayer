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
import SmoothFFmpeg

public class MViewController: NSViewController {
    
    @IBOutlet var playerView: PlayerView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        guard let path = Bundle.main.path(forResource: "sample", ofType: "mp4") else {
            assertionFailure()
            return
        }
        self.playerView?.play(path: path)
    }
    @IBAction func click(_ sender: AnyObject) {
        if self.playerView?.isFinished ?? false {
            self.playerView?.play()
        } else {
            self.playerView?.stop()
        }
    }
}
