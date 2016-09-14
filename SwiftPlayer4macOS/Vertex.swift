//
//  Vertex.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation

struct Vertex {
    var x, y, z: Float
    var r, g, b, a: Float
    
    var floatBuffer: [Float] {
        return [x, y, z, r, g, b, a]
    }
}
