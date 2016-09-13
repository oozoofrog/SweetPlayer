//
//  Player.swift
//  SwiftPlayer
//
//  Created by Kwanghoon Choi on 2016. 8. 29..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import ffmpeg
import AVFoundation
import Accelerate

class Player {
    let path: String
    let format: SweetFormat
    init?(path: String) {
        self.path = path
        guard let format = SweetFormat(path: path) else {
            return nil
        }
        self.format = format
    }
    
    var videoSize: CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    func cancel() {
        
    }
}
