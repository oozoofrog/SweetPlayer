//
//  Light.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 22..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation

struct Light {
    
    var color: (Float, Float, Float)
    var ambientIntensity: Float
    var direction: (Float, Float, Float)
    var diffuseIntensity: Float
    var shininess: Float
    var specularIntensity: Float
    
    static func size() -> Int {
        return MemoryLayout<Float>.size * 12
    }
    
    static func count() -> Int {
        return size() / MemoryLayout<Float>.stride
    }
    
    func raw() -> [Float] {
        //return [color.0, color.1, color.2, ambientIntensity, direction.0, direction.1, direction.2, diffuseIntensity]
        var light = self
        let buffer: UnsafeMutablePointer<Float> = withUnsafeMutablePointer(to: &light) { (ptr) -> UnsafeMutablePointer<Float> in
            return ptr.withMemoryRebound(to: Float.self, capacity: Light.count()){$0}
        }
        return [Float](UnsafeBufferPointer(start: buffer, count: Light.count()))
    }
}
