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
    
    static func size() -> Int {
        return MemoryLayout<Float>.size * 4
    }
    
    func raw() -> [Float] {
        let raw = [color.0, color.1, color.2, ambientIntensity]
        return raw
    }
}
