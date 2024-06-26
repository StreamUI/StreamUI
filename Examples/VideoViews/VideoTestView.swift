//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import AVFoundation
import AVKit
import Foundation
import StreamUI
import SwiftUI

// class VideoFrameCaptureManager: ObservableObject {
//    @Published var frame: CGImage?
//
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
//
//    init(url: URL) {
//        self.player = AVPlayer(url: url)
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//        player.currentItem?.add(videoOutput)
//        player.play()
//
//        addPeriodicTimeObserver()
//    }
//
//    private func addPeriodicTimeObserver() {
//        let timeInterval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] _ in
//            self?.captureCurrentFrame()
//        }
//    }
//
//    private func captureCurrentFrame() {
//        let currentTime = CACurrentMediaTime()
//        let itemTime = videoOutput.itemTime(forHostTime: currentTime)
//
//        guard videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
//              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil)
//        else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                self.frame = cgImage
//            }
//        }
//    }
// }
//
// struct VideoFrameView: View {
//    @StateObject private var videoFrameCaptureManager: VideoFrameCaptureManager
//
//    init(url: URL) {
//        _videoFrameCaptureManager = StateObject(wrappedValue: VideoFrameCaptureManager(url: url))
//    }
//
//    var body: some View {
//        Group {
//            if let frame = videoFrameCaptureManager.frame {
//                Image(decorative: frame, scale: 1.0, orientation: .up)
//                    .resizable()
//                    .scaledToFit()
//            } else {
//                Text("Loading...")
//                    .frame(height: 400)
//            }
//        }
//        .frame(height: 400)
//    }
// }

public struct VideoTestView: View {
    @Environment(\.recorder) private var recorder

    let url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"

    public init() {}
    public var body: some View {
        StreamingVideoPlayer(url: URL(string: url)!)
//        MediaPlayerView(url: URL(string: url)!)
            .frame(width: 500, height: 900)

//        VideoPlayer(player: AVPlayer(url: URL(string: "https://file-examples.com/storage/fed5266c9966708dcaeaea6/2017/04/file_example_MP4_480_1_5MG.mp4")!))
//            .frame(height: 400)
    }
}
