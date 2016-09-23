//
//  Player.swift
//  SwiftPlayer
//
//  Created by Kwanghoon Choi on 2016. 8. 29..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

class Player {
    
    let path: String
    let format: SweetFormat
    
    init?(path: String) {
        self.path = path
        av_register_all()
        avformat_network_init()
        guard let format = SweetFormat(path: path) else {
            return nil
        }
        self.format = format
        self.initialize()
    }
    
    private func initialize() {
        self.playVideoStreamAt = 0
        self.playAudioStreamAt = 0
    }
    
    deinit {
        avformat_network_deinit()
    }
    
    var videoSize: CGSize {
        guard let videoStream = self.format.stream(forType: AVMEDIA_TYPE_VIDEO) else {
            return CGSize()
        }
        return videoStream.videoSize
    }
    
    var fps: Double {
        return self.format.stream(forType: AVMEDIA_TYPE_VIDEO)?.fps ?? 0.0
    }
    
    func cancel() {
        
    }
    
    var videoStreamIndex: Int32 = -1
    var audioStreamIndex: Int32 = -1
    
    var playVideoStreamAt: Int {
        set {
            guard let stream = self.videos?[newValue] else {
                return
            }
            videoStreamIndex = stream.index
        }
        get {
            guard 0 <= videoStreamIndex, let streams = self.videos else {
                return -1
            }
            
            return streams.index(where: { $0.index == videoStreamIndex}) ?? -1
        }
    }
    var playAudioStreamAt: Int {
        set {
            guard let stream = self.audios?[newValue] else {
                return
            }
            audioStreamIndex = stream.index
        }
        get {
            guard 0 <= audioStreamIndex, let streams = self.audios else {
                return -1
            }
            
            return streams.index(where: { $0.index == audioStreamIndex}) ?? -1
        }
    }
    
    
    var audios: [SweetStream]? {
        return self.format.streamsByType[AVMEDIA_TYPE_AUDIO]
    }
    
    var audio: SweetStream? {
        return self.audios?[self.playAudioStreamAt]
    }
    
    var videos: [SweetStream]? {
        return self.format.streamsByType[AVMEDIA_TYPE_VIDEO]
    }
    
    var video: SweetStream? {
        return self.videos?[self.playVideoStreamAt]
    }
    
    var packet: AVPacket = AVPacket()
    var frame: AVFrame = AVFrame()
    enum PlayerDecoded {
        case audio(AudioData)
        case video(VideoData)
        case unknown
        case finish
    }
    func decodeFrame() -> PlayerDecoded {
        
        while 0 <= av_read_frame(self.format.formatContext, &packet) {
            
            let streamIndex = Int(packet.stream_index)
            guard streamIndex < self.format.streams.count, audioStreamIndex == packet.stream_index || videoStreamIndex == packet.stream_index else {
                return .unknown
            }
            let stream = self.format.streams[streamIndex]
            switch stream.decode(&packet, frame: &frame) {
            case .err(let err):
                print_err(err, #function)
                return .finish
            case .success:
                break
            }
            switch stream.type {
            case AVMEDIA_TYPE_VIDEO:
                guard let data = frame.videoData(stream.time_base) else {
                    return .unknown
                }
                return .video(data)
            case AVMEDIA_TYPE_AUDIO:
                
                guard let data = frame.audioData(stream.time_base) else {
                    return .unknown
                }
                return .audio(data)
            default:
                return .unknown
            }
        }
        
        return .unknown
    }
}
