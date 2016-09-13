//
//  DataContainer.swift
//  SwiftPlayer
//
//  Created by jayios on 2016. 9. 13..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import ffmpeg
import AVFoundation
import Accelerate

protocol MediaTimeDatable {
    var pts: Int64 { get }
    var dur: Int64 { get }
    var end: Int64 { get }
    var time_base: AVRational { get }
    var time: Double { get }
    var timeRange: Range<Double> { get }
}

extension MediaTimeDatable {
    var end: Int64 {
        return dur + pts == Int64.min ? 0 : pts
    }
    var time: Double {
        if pts == Int64.min {
            return 0
        }
        return Double(pts) * av_q2d(time_base)
    }
    var timeRange: Range<Double> {
        return time..<(Double(end) * av_q2d(time_base))
    }
}

struct VideoData: MediaTimeDatable {
    let y: Data
    let u: Data
    let v: Data
    
    let lumaLength: Int32
    let chromaLength: Int32
    
    let w: Int32
    let h: Int32
    
    let pts: Int64
    let dur: Int64
    let time_base: AVRational
}

struct AudioData: MediaTimeDatable {
    var data: Data
    let format: AVAudioFormat
    var channels: AVAudioChannelCount {
        return format.channelCount
    }
    var bufferSize: Int
    var sampleSize: Int
    
    var pcmBuffer: AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferSize))
        buffer.frameLength = AVAudioFrameCount(sampleSize)
        let floatBuffer: UnsafePointer<Float> = data.withUnsafeBytes { (ptr) -> UnsafePointer<Float> in
            return ptr
        }
        for i in 0..<channels {
            guard let channel = buffer.floatChannelData?[Int(i)] else {
                continue
            }
            cblas_scopy(Int32(sampleSize), floatBuffer.advanced(by: Int(i)), 2, channel, 1)
        }
        
        return buffer
    }
    
    let pts: Int64
    let dur: Int64
    let time_base: AVRational
}
