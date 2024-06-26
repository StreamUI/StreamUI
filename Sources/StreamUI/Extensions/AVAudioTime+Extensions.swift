//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import AVFoundation
import Foundation

extension AVAudioTime {
    func toCMTime() -> CMTime {
        let sampleTime = CMTimeMake(value: Int64(self.sampleTime), timescale: 1)
        let sampleRate = CMTimeMake(value: Int64(self.sampleRate), timescale: 1)
        return CMTimeMultiplyByRatio(sampleTime, multiplier: sampleRate.timescale, divisor: Int32(sampleRate.value))
    }
}
