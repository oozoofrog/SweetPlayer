//
//  ViewController.swift
//  SwiftPlayer4macOS
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: MetalViewController, MetalViewControllerDelegate {
    
    var worldModelMatrix: Matrix4!
    var objectToDraw: Cube!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.worldModelMatrix = Matrix4()
        worldModelMatrix.translate(0, y: 0, z: -4)
        worldModelMatrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0, z: 0)
        
        objectToDraw = Cube(device: self.device)
        self.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func renderObjects(_ drawable: CAMetalDrawable) {
        objectToDraw.render(commandQueue: self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMarix, clearColor: nil)
    }
    
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
        objectToDraw.update(withDelta: timeSinceLastUpdate)
    }
}

