//
//  Triangle.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import Metal

class Triangle: Node {
    init(device: MTLDevice) {
        let v0 = Vertex(x: 0, y: 1.0, z: 0, r: 1.0, g: 0, b: 0, a: 1.0)
        let v1 = Vertex(x: -1, y: -1, z: 0, r: 0, g: 1, b: 0, a: 1)
        let v2 = Vertex(x: 1, y: -1, z: 0, r: 0, g: 0, b: 1, a: 1)
        
        let verticesArray = [v0, v1, v2]
        super.init(name: "Triangle", vertices: verticesArray, device: device)
    }
}
