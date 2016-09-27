//
//  FFmpegHelper.swift
//  tutorial
//
//  Created by jayios on 2016. 9. 7..
//  Copyright © 2016년 gretech. All rights reserved.
//

import Foundation
import AVFoundation

extension AVFrame {
    mutating func videoData(_ time_base: AVRational, isRGB24: Bool = false) -> VideoData? {
        
        if 0 < self.width && 0 < self.height {
            
            let pts = av_frame_get_best_effort_timestamp(&self)
            if isRGB24 {
                guard let rgbBuf = self.data.0 else {
                    return nil
                }
                let size = Int(self.linesize.0 * self.height)
                let rgb = Data(bytes: rgbBuf, count: size)
                return VideoData(y: rgb, u: Data(), v: Data(), lumaLength: self.linesize.0, chromaLength: 0, w: self.width, h: self.height, pts: pts, dur: self.pkt_duration, time_base: time_base)
            } else {
                guard let ybuf = self.data.0 else {
                    return nil
                }
                
                let lumaSize = Int(self.linesize.0 * self.height)
                let chromaSize = Int(self.linesize.1 * self.height / 2)
                let y = Data(bytes: ybuf, count: lumaSize)
                guard let ubuf = self.data.1 else {
                    return nil
                }
                let u = Data(bytes: ubuf, count: chromaSize)
                guard let vbuf = self.data.2 else {
                    return nil
                }
                let v = Data(bytes: vbuf, count: chromaSize)
                return VideoData(y: y, u: u, v: v, lumaLength: self.linesize.0, chromaLength: self.linesize.1, w: self.width, h: self.height, pts: pts, dur: self.pkt_duration, time_base: time_base)
            }
        }
        
        return nil
    }
    
    mutating func dataCount() -> Int {
        let dataPtr = Array(UnsafeBufferPointer.init(start: &self.data.0, count: 8))
        
        return dataPtr.reduce(0, { (result, ptr) -> Int in
            return nil == ptr ? result : result + 1
        })
    }
    
    mutating func audioData(_ time_base: AVRational) -> AudioData? {
        let format = MediaHelper.audioDefaultFormat
        return AudioData(data: Data(bytes: self.data.0!, count: Int(linesize.0)), format: format, bufferSize: Int(linesize.0), sampleSize: Int(nb_samples), pts: av_frame_get_best_effort_timestamp(&self), dur: self.pkt_duration, time_base: time_base)
    }
}

extension AVFormatContext {
    mutating func streamArray(_ type: AVMediaType) -> [SweetStream] {
        var streams: [SweetStream] = []
        for i in 0..<Int32(self.nb_streams) {
            guard let s = SweetStream(format: &self, type: type, index: i), s.open() else {
                continue
            }
            streams.append(s)
        }
        return streams
    }
}

extension AVCodecContext {
    var videoSize: CGSize {
        if 0 < self.width && 0 < self.height {
            return CGSize(width: Int(self.width), height: Int(self.height))
        }
        return CGSize()
    }
}

extension AVMediaType: Hashable {
    public var hashValue: Int {
        return Int(self.rawValue)
    }
}

class SweetFormat {
    var formatContext: UnsafeMutablePointer<AVFormatContext>?
    let path: String
    fileprivate(set) var streamsByType: [AVMediaType: [SweetStream]] = [AVMediaType:[SweetStream]]()
    fileprivate(set) var streams: [SweetStream] = []
    init?(path: String) {
        self.path = path
        guard av_success_desc(avformat_open_input(&formatContext, path, nil, nil), "open failed -> \(path)") else {
            return nil
        }
        guard av_success_desc(avformat_find_stream_info(formatContext, nil), "find stream info") else {
            return nil
        }
        
        if let videos = self.formatContext?.pointee.streamArray(AVMEDIA_TYPE_VIDEO) {
            self.streamsByType[AVMEDIA_TYPE_VIDEO] = videos
        }
        if let audios = self.formatContext?.pointee.streamArray(AVMEDIA_TYPE_AUDIO) {
            self.streamsByType[AVMEDIA_TYPE_AUDIO] = audios
        }
        if 0 == self.streamsByType.count {
            return nil
        }
        if let subtitles = self.formatContext?.pointee.streamArray(AVMEDIA_TYPE_SUBTITLE).filter({$0.open()}) {
            self.streamsByType[AVMEDIA_TYPE_SUBTITLE] = subtitles
        }
        self.streamsByType.forEach { (key, value) in
            self.streams.append(contentsOf: value)
        }
        self.streams.sort(by: {$0.0.index < $0.1.index})
    }
    
    deinit {
        avformat_close_input(&formatContext)
    }
    
    func streams(forType type: AVMediaType) -> [SweetStream]? {
        guard self.streamsByType.contains(where: {$0.0 == type}) else {
            return nil
        }
        return self.streamsByType[type]
    }
    
    func stream(forType type: AVMediaType) -> SweetStream? {
        return self.streams(forType: type)?.first
    }
    
    func stream(forType type: AVMediaType, at: Int = -1) -> SweetStream? {
        guard let streams = self.streams(forType: type) else {
            return nil
        }
        
        if 0 <= at && at < streams.count {
            return streams[at]
        }
        return nil
    }
    
    func stream(forType type: AVMediaType, index: Int32 = -1) -> SweetStream? {
        
        guard let streams = self.streamsByType[type] else {
            return nil
        }
        
        if -1 == index {
            return streams.first
        }
        for stream in streams {
            if stream.index == index {
                return stream
            }
        }
        
        return nil
    }
}

class SweetStream: CustomStringConvertible {
    
    var description: String {
        let codecpar = self.stream.pointee.codecpar.pointee
        return "codec: \(codecpar.codec_id), media_type: \(codecpar.codec_type), color_primaries: \(codecpar.color_primaries), color_space: \(codecpar.color_space)"
    }
    
    let format: UnsafeMutablePointer<AVFormatContext>
    let index: Int32
    let stream: UnsafeMutablePointer<AVStream>
    var codec: UnsafeMutablePointer<AVCodecContext>? = nil
    let type: AVMediaType
    var filter: AVFilterHelper?
    var w: Int32 {
        guard let c = self.codec else {
            return 0
        }
        return c.pointee.width
    }
    var h: Int32 {
        guard let c = self.codec else {
            return 0
        }
        return c.pointee.height
    }
    
    var videoSize: CGSize {
        return CGSize(width: Int(w), height: Int(h))
    }
    
    var fps: Double {
        let fps = av_q2d(self.stream.pointee.avg_frame_rate)
        return fps
    }
    
    var time_base: AVRational {
        switch self.type {
        case AVMEDIA_TYPE_AUDIO, AVMEDIA_TYPE_VIDEO:
            return self.stream.pointee.time_base
        default:
            return AVRational()
        }
    }
    
    var colorSpace: AVColorSpace {
        return self.stream.pointee.codecpar.pointee.color_space
    }
    
    init?(format: UnsafeMutablePointer<AVFormatContext>?, type: AVMediaType = AVMEDIA_TYPE_UNKNOWN, index: Int32 = -1) {
        guard let f = format else {
            return nil
        }
        self.format = f
        self.type = type
        
        guard type != AVMEDIA_TYPE_UNKNOWN || 0 <= index else {
            assertionFailure("must have type or positive index.")
            return nil
        }
        if 0 <= index {
            if index >= Int32(self.format.pointee.nb_streams) {
                return nil
            }
            self.index = index
        } else {
            self.index = av_find_best_stream(format, type, -1, -1, nil, 0)
            if 0 > self.index {
                return nil
            }
        }
        guard let s = self.format.pointee.streams[Int(self.index)], s.pointee.codecpar.pointee.codec_type == type else {
            return nil
        }
        self.stream = s
    }
    
    func open() -> Bool {
        guard let c = avcodec_find_decoder(self.stream.pointee.codecpar.pointee.codec_id) else {
            return false
        }
        self.codec = avcodec_alloc_context3(c)
        guard av_success(avcodec_parameters_to_context(self.codec, self.stream.pointee.codecpar)) else {
            return false
        }
        self.codec?.pointee.thread_count = 2
        self.codec?.pointee.thread_type = FF_THREAD_FRAME
        guard av_success(avcodec_open2(self.codec, c, nil)) else {
            return false
        }
        print("open stream -> \(self)")
        return true
    }
    
    deinit {
        avcodec_free_context(&codec)
    }
    
    enum SweetDecodeResult {
        case err(Int32)
        case success
    }
    
    func decode(_ pkt: UnsafeMutablePointer<AVPacket>, frame: UnsafeMutablePointer<AVFrame>) -> SweetDecodeResult{
        var ret = avcodec_send_packet(self.codec, pkt)
        if 0 > ret && ret != AVERROR_CONVERT(EAGAIN) && false == IS_AVERROR_EOF(ret) {
            return .err(ret)
        }
        ret = avcodec_receive_frame(self.codec, frame)
        if 0 > ret {
            return ret == AVERROR_CONVERT(EAGAIN) ? .success : .err(ret)
        }
        switch self.filter?.applyFilter(frame) {
        case AVFilterApplyResult.success?:
            return .success
        default:
            break
        }
        return .success
    }
    
    func filtering(frame: UnsafeMutablePointer<AVFrame>) -> AVFilterApplyResult {
        return self.filter?.applyFilter(frame) ?? .failed
    }
    
    func setupVideoFilter() {
        if let _ = self.filter {
            return
        }
        self.filter = AVFilterHelper()
        guard self.filter?.setup(self.format, videoStream: self.stream, filterDescription: "format=pix_fmts=rgb24") ?? false else {
            self.filter = nil
            return
        }
    }
    
    func setupAudioFilter(
        _ outSampleRate: Int32,
        outSampleFmt: AVSampleFormat,
        outChannels: Int32) -> Bool{
        
        let inSampleRate: Int32 = self.stream.pointee.codecpar.pointee.sample_rate
        let inSampleFmt: AVSampleFormat = AVSampleFormat(rawValue: self.stream.pointee.codecpar.pointee.format)
        let inTimeBase: AVRational = self.time_base
        let inChannelLayout: UInt64 = self.stream.pointee.codecpar.pointee.channel_layout
        let inChannels: Int32 = self.stream.pointee.codecpar.pointee.channels
        
        self.filter = AVFilterHelper()
        //TODO: setup filter
        var sbuf = [Int8](repeating: 0, count: 64)
        av_get_channel_layout_string(&sbuf, Int32(sbuf.count), inChannels, inChannelLayout)
        let inChannelLayoutString = String(cString: sbuf)
        guard 0 < inChannelLayoutString.lengthOfBytes(using: .utf8) else {
            return false
        }
        sbuf = [Int8](repeating: 0, count: 64)
        let outChannelLayout = av_get_default_channel_layout(outChannels)
        av_get_channel_layout_string(&sbuf, Int32(sbuf.count), outChannels, UInt64(outChannelLayout))
        let outChannelLayoutString = String(cString: sbuf)
        guard 0 < outChannelLayoutString.lengthOfBytes(using: .utf8) else {
            return false
        }
        let inTimeBaseStr = "\(inTimeBase.num)/\(inTimeBase.den)"
        let inSampleFormatStr = String(cString: av_get_sample_fmt_name(inSampleFmt))
        let outSampleFormatStr = String(cString: av_get_sample_fmt_name(outSampleFmt))
        
        return filter?.setup(
            format,
            audioStream: stream,
            abuffer: "sample_rate=\(inSampleRate):sample_fmt=\(inSampleFormatStr):time_base=\(inTimeBaseStr):channels=\(inChannels):channel_layout=\(inChannelLayoutString)",
            aformat: "sample_rates=\(outSampleRate):sample_fmts=\(outSampleFormatStr):channel_layouts=\(outChannelLayoutString)") ?? false
    }
}

protocol Namer: CustomDebugStringConvertible {
    var name:String { get }
    var debugDescription: String { get }
}

extension Namer {
    var name: String {
        return ""
    }
    
    public var debugDescription: String {
        return self.name
    }
}

extension AVCodecID: Namer {
    public var name: String {
        let name = String.init(cString: avcodec_get_name(self))
        return name
    }
}

extension AVMediaType: Namer {
    public var name: String {
        let name = String(cString: av_get_media_type_string(self))
        return name
    }
}

extension AVColorPrimaries: Namer {
    var name: String {
        var name: String = "color primaries "
        switch self {
        case AVCOL_PRI_BT2020:
            name += "bt20202"
        case AVCOL_PRI_BT709:
            name += "bt709"
        default:
            name += "bt601"
        }
        return name
    }
}

extension AVColorSpace: Namer {
    var name: String {
        var name: String = "color space "
        switch self {
        case AVCOL_SPC_BT2020_CL, AVCOL_SPC_BT2020_NCL:
            name += "bt2020"
        case AVCOL_SPC_BT709:
            name += "bt709"
        default:
            name += "bt601"
        }
        return name
    }
}

protocol Convolutioner {
    var matrix: ColorMatrix { get }
}

extension AVColorSpace: Convolutioner {
    var matrix: ColorMatrix {
        switch self {
        case AVCOL_SPC_BT709:
            return ColorMatrix.bt709
        case AVCOL_SPC_BT2020_CL, AVCOL_SPC_BT2020_NCL:
            return ColorMatrix.bt2020
        default:
            return ColorMatrix.bt601
        }
    }
}

extension AVColorPrimaries: Convolutioner {
    var matrix: ColorMatrix {
        switch self {
        case AVCOL_PRI_BT709:
            return ColorMatrix.bt709
        case AVCOL_PRI_BT2020:
            return ColorMatrix.bt2020
        default:
            return ColorMatrix.bt601
        }
    }
}
