//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/19/24.
//

import AVFoundation
import Foundation
import SwiftUI

struct VideoFrame {
    let image: CGImage
    let time: CMTime
}

class FrameStream {
    private var continuation: AsyncStream<VideoFrame>.Continuation?

    var stream: AsyncStream<VideoFrame> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func enqueue(_ frame: CGImage, withTime frameTime: CMTime) {
        continuation?.yield(VideoFrame(image: frame, time: frameTime))
    }

    func finish() {
        continuation?.finish()
    }
}
