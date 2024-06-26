//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/21/24.
//

import AVFoundation
import Foundation

struct AudioSample {
    let buffer: AVAudioPCMBuffer
    let time: CMTime
}

class AudioStream {
    private var continuation: AsyncStream<AudioSample>.Continuation?

    var stream: AsyncStream<AudioSample> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func enqueue(_ buffer: AVAudioPCMBuffer, withTime time: CMTime) {
        continuation?.yield(AudioSample(buffer: buffer, time: time))
    }

    func finish() {
        continuation?.finish()
    }
}
