//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/24/24.
//

import CoreMedia
import Foundation

public class FrameTimer {
    private var startTime: CMTime?
    public var frameCount: Int = 0
    private let frameRate: Double
    
    init(frameRate: Double) {
        self.frameRate = frameRate
    }
    
    func start() {
        startTime = CMClockGetTime(CMClockGetHostTimeClock())
        frameCount = 0
    }
    
    func getCurrentFrameTime() -> CMTime {
        return CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(frameRate))
    }
    
    func incrementFrame() {
        frameCount += 1
    }
}
