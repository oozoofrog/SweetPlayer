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
    
    private var audioHelper: MediaHelper?
    private var videoQueue: Queue<VideoData>?
    
    private var playing: Bool = false
    public var isPlaying: Bool {
        return playing
    }
    private var paused: Bool = false
    public var isPaused: Bool {
        return paused
    }
    private var quit: Bool = false
    public var isFinished: Bool {
        self.decodeLock.wait()
        let finished = self.quit
        let empty = self.videoQueue?.isEmpty ?? true
        self.decodeLock.signal()
        
        return finished && empty
    }
    private var decodeQueue: DispatchQueue = DispatchQueue(label: "com.sweetplayer.player.decode")
    private let decodeLock: DispatchSemaphore = DispatchSemaphore(value: 1)
    
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
        
        if let fps = self.video?.fps {
            self.videoQueue = Queue(maxQueueCount: 16, framePeriod: 1.0 / fps)
        }
        if let audio = self.audio {
            let audioHelper = MediaHelper()
            if audioHelper.setupAudio(forAudioStream: audio) {
                self.audioHelper = audioHelper
            }
        }
    }
    
    deinit {
        avformat_network_deinit()
    }
    
    var video: SweetStream? {
        return self.format.stream(forType: AVMEDIA_TYPE_VIDEO, at: self.playVideoStreamAt)
    }
    
    var audio: SweetStream? {
        return self.format.stream(forType: AVMEDIA_TYPE_AUDIO, at: self.playAudioStreamAt)
    }
    
    var videoSize: CGSize {
        guard let videoStream = self.video else {
            return CGSize()
        }
        return videoStream.videoSize
    }
    
    var fps: Double {
        return self.format.stream(forType: AVMEDIA_TYPE_VIDEO)?.fps ?? 0.0
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
    
    var videos: [SweetStream]? {
        return self.format.streamsByType[AVMEDIA_TYPE_VIDEO]
    }
    
    public func stop() {
        self.decodeLock.wait()
        self.timestamp = 0
        self.quit = true
        self.videoQueue?.clear()
        self.format.seek()
        self.audioHelper?.stop()
        self.decodeLock.signal()
    }
    
    public func start() {
        self.decodeLock.wait()
        self.quit = false
        self.audioHelper?.start()
        self.decodeLock.signal()
        self.decodeQueue.async {
            
            var packet: AVPacket = AVPacket()
            var frame: AVFrame = AVFrame()
 
            self.video?.flush()
            self.audio?.flush()
            while true {
                self.decodeLock.wait()
                defer {
                    self.decodeLock.signal()
                }
                if self.quit {
                    break
                }
                if self.videoQueue?.full ?? false || self.quit {
                    continue
                }
                
                guard false == self.quit, 0 <= av_read_frame(self.format.formatContext, &packet) else {
                    break
                }
                
                let streamIndex = Int(packet.stream_index)
                guard false == self.quit, streamIndex < self.format.streams.count, self.audioStreamIndex == packet.stream_index || self.videoStreamIndex == packet.stream_index else {
                    continue
                }
                let stream = self.format.streams[streamIndex]
                switch stream.decode(&packet, frame: &frame) {
                case .err(let err):
                    print_err(err, #function)
                    return
                case .success:
                    break
                }
                switch stream.type {
                case AVMEDIA_TYPE_VIDEO:
                    guard let data = frame.videoData(stream.time_base), false == self.quit else {
                        continue
                    }
                    self.videoQueue?.append(data: data)
                case AVMEDIA_TYPE_AUDIO:
                    
                    guard let data = frame.audioData(stream.time_base), false == self.quit else {
                        continue
                    }
                    self.audioHelper?.audioPlay(data)
                default:
                    continue
                }
            }
        }
    }
    
    var timestamp: Double = 0
    var timeprogress: Double {
        let currentTimestamp = CFAbsoluteTimeGetCurrent()
        if 0 == self.timestamp {
            self.timestamp = currentTimestamp
        }
        return currentTimestamp - self.timestamp
    }

    public func requestVideoFrame() -> PlayerDecoded {
        self.decodeLock.wait()
        defer {
            self.decodeLock.signal()
        }
        if let data = self.videoQueue?.request(timestamp: self.timeprogress) {
            return .video(data)
        }
        return .unknown
    }
}

enum PlayerDecoded {
    case audio(AudioData)
    case video(VideoData)
    case unknown
    case finish
}

fileprivate struct Queue<Data: MediaTimeDatable> {
    
    let maxQueueCount: Int
    let framePeriod: Double
    
    var full: Bool {
        return maxQueueCount <= self.queue.count
    }
    
    var isEmpty: Bool {
        return self.queue.count == 0
    }
    
    var queue: [Data]
    init(maxQueueCount: Int, framePeriod: Double) {
        self.maxQueueCount = maxQueueCount
        self.framePeriod = framePeriod
        self.queue = []
    }
    
    mutating func clear() {
        self.queue.removeAll(keepingCapacity: true)
    }
    
    mutating func append(data: Data) {
        self.queue.append(data)
    }
    
    mutating func request(timestamp: Double, fixFrame: Bool = false) -> Data? {
        let filtered = self.queue.filter({$0.time > timestamp - framePeriod})
        self.queue = filtered
        guard let firstData = self.queue.first else {
            return nil
        }
        if firstData.time <= timestamp + framePeriod && false == fixFrame {
            self.queue.removeFirst()
        }
        return firstData
    }
}
