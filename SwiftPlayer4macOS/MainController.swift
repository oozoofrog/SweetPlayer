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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.view.wantsLayer = true
        
        let bg: NSColor = NSColor(colorLiteralRed: 235 / 255.0, green: 82 / 255.0, blue: 63 / 255.0, alpha: 1.0)
        self.view.layer?.backgroundColor = bg.cgColor
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
        let _ = playerView.play(path: url.absoluteString)
    }
}
