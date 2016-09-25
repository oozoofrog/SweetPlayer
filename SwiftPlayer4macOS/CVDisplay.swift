//
//  DisplayUtil.swift
//  SwiftPlayer
//
//  Created by mayjay on 2016. 9. 25..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Foundation
import CoreVideo

public protocol CVDisplayDelegate {
    func refresh(link: CVDisplayLink, time: CVTimeStamp)
}

public class CVDisplay {
    
    var displayLink: CVDisplayLink
    var delegate: CVDisplayDelegate?
    
    var refreshRate: Int {
        let period = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(self.displayLink)
        return Int(round(Double(period.timeScale) / Double(period.timeValue)))
    }
    
    public init?() {
        var displayLink: CVDisplayLink?
        guard kCVReturnSuccess == CVDisplayLinkCreateWithActiveCGDisplays(&displayLink) else {
            return nil
        }
        self.displayLink = displayLink!
    }
    
    public func start(handler: CVDisplayLinkOutputHandler?) throws {
        guard kCVReturnSuccess == CVDisplayLinkStart(self.displayLink) else {
            throw CVDisplayFailed
        }
        guard kCVReturnSuccess == CVDisplayLinkSetOutputHandler(self.displayLink, { (link, inTime, outTime, inOpts, outOpts) -> CVReturn in
            self.delegate?.refresh(link: link, time: inTime.pointee)
            return handler?(link, inTime, outTime, inOpts, outOpts) ?? kCVReturnSuccess
        }) else {
            throw CVDisplayFailed
        }
    }
    
    public func stop() {
        CVDisplayLinkStop(self.displayLink)
    }
}

public let CVDisplayFailed: Error = NSError(domain: "CVDisplay", code: 0, userInfo: nil) as Error
