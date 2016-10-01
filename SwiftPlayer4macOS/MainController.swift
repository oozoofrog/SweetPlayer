//
//  MainController.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 10. 1..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Cocoa
import SmoothFFmpeg

class MainController: NSViewController, NSOpenSavePanelDelegate {
    
    @IBOutlet var playerView: PlayerView!
    @IBOutlet var progressView: NSProgressIndicator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.view.wantsLayer = true
        
        let bg: NSColor = NSColor(colorLiteralRed: 235 / 255.0, green: 82 / 255.0, blue: 63 / 255.0, alpha: 1.0)
        self.view.layer?.backgroundColor = bg.cgColor
        
        self.progressView.minValue = 0.0
        self.progressView.maxValue = 1.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.titlebarAppearsTransparent = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "SweetPlayer"
        
        //  self.open()
    }
    
    @IBAction func clickProgress(_ sender: NSClickGestureRecognizer) {
        let p = Double(sender.location(in: sender.view).x / self.view.bounds.width)
        self.playerView.player?.seek(seek: self.playerView.player?.time(fromProgress: p) ?? 0)
    }
    //MARK: - Actions
    
    func open() {
        guard let window = self.view.window else {
            return
        }
        let open = NSOpenPanel()
        open.directoryURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        open.delegate = self
        open.beginSheetModal(for: window) { (code) in
            switch code {
            case 1:
                
                break
            default:
                break
            }
        }
    }
    
    func panel(_ sender: Any, validate url: URL) throws {
        guard playerView.setup(path: url.absoluteString, progressHandle: { (player, progress) in
            self.progressView.doubleValue = progress
        }) else {
            return
        }
        let _ = playerView.play()
    }
}

class ProgressView: NSProgressIndicator {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    var entered: Bool = false
    override func mouseEntered(with event: NSEvent) {
        if false == entered {
            entered = true
            NSAnimationContext.runAnimationGroup({ (ctx) in
                ctx.duration = 2
                self.layer?.transform = CATransform3DConcat(CATransform3DMakeTranslation(0, -self.bounds.size.height / 3, 0), CATransform3DMakeScale(1, 2.0, 1))
                }, completionHandler: nil)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if entered {
            entered = false
            NSAnimationContext.runAnimationGroup({ (ctx) in
                ctx.duration = 2
                self.layer?.transform = CATransform3DIdentity
                }, completionHandler: nil)
        }
    }
    var trackingArea: NSTrackingArea? = nil
    override func updateTrackingAreas() {
        if let area = self.trackingArea {
            self.removeTrackingArea(area)
        }
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }
}
