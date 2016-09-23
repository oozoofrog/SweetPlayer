//
//  ViewController.swift
//  SwiftPlayer4macOS
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Cocoa
import MetalKit
import simd

class ViewController: MetalViewController, MetalViewControllerDelegate {
    
    var worldModelMatrix: float4x4!
    var objectToDraw: Cube!
    
    let panSensitivity: Float = 5.0
    var lastPanLocation: CGPoint = CGPoint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.worldModelMatrix = float4x4()
        worldModelMatrix.translate(0, y: 0, z: -4)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 25), y: 0, z: 0)
        
        objectToDraw = Cube(device: self.device, commandQueue: self.commandQueue)
        self.delegate = self
        
        self.setupGesture()
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
        objectToDraw.render(self.commandQueue, pipelineState: self.pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMarix, clearColor: nil)
    }
    
    func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
//        objectToDraw.update(withDelta: timeSinceLastUpdate)
    }
    
    func setupGesture() {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(ViewController.pan(gesture:)))
        self.view.addGestureRecognizer(pan)
    }
    
    func pan(gesture: NSPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastPanLocation = gesture.location(in: gesture.view)
        case .changed:
            let pointInView = gesture.location(in: gesture.view)
            let xDelta = Float((lastPanLocation.x - pointInView.x) / self.view.bounds.width) * panSensitivity
            let yDelta = Float((lastPanLocation.y - pointInView.y) / self.view.bounds.height) * panSensitivity
            objectToDraw.rotation.y -= xDelta
            objectToDraw.rotation.x += yDelta
            lastPanLocation = pointInView
        default:
            break
        }
    }
}

