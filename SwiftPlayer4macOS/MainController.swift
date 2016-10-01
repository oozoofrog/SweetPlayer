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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layer = CALayer()
        layer.backgroundColor = NSColor.black.cgColor
        self.view.layer = layer
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.open()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        self.view.layer?.frame = self.view.bounds
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
