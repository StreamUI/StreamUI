//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/21/24.
//

// RTMPStreaming.swift

import AVFoundation
import Foundation
import HaishinKit
import VideoToolbox

public class RTMPStreaming: ObservableObject {
    public var renderSettings: RenderSettings
    @Published public var isStreaming: Bool = false
    
    private var rtmpStreams: [RTMPStream] = []
    private var rtmpConnections: [RTMPConnection] = []
    private var lastSampleBufferTimestamp: CMTime?
    
    // Properties for frame rate logging
    private var frameCount: Int = 0
    private var startTime: Date?
    private let logInterval: TimeInterval = 5.0 // Log every 5 seconds

    public init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
        setupRTMPStreams()
    }
    
    private func setupRTMPStreams() {
        guard let liveStreamSettings = renderSettings.livestreamSettings else { return }
        
        for settings in liveStreamSettings {
            let rtmpConnection = RTMPConnection()
            let rtmpStream = RTMPStream(connection: rtmpConnection)
            
            configureRTMPStream(rtmpStream, with: settings)
            
            rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            
            rtmpConnections.append(rtmpConnection)
            rtmpStreams.append(rtmpStream)
        }
    }
    
    private func configureRTMPStream(_ rtmpStream: RTMPStream, with streamSettings: LivestreamSettings) {
//        rtmpStream.videoSettings.videoSize = CGSize(width: CGFloat(renderSettings.width), height: CGFloat(renderSettings.height))
//        rtmpStream.videoSettings.profileLevel = streamSettings.profileLevel ?? kVTProfileLevel_H264_Main_AutoLevel as String
//        rtmpStream.videoSettings.bitRate = streamSettings.bitRate ?? renderSettings.getDefaultBitrate()
//        rtmpStream.videoSettings.profileLevel = kVTProfileLevel_H264_Baseline_AutoLevel as String
//        rtmpStream.videoSettings.bitRate = 1200 * 1000
//        rtmpStream.videoSettings.maxKeyFrameIntervalDuration = 2
//        rtmpStream.videoSettings.scalingMode = .trim
        
        let bitrate = renderSettings.getDefaultBitrate()
        rtmpStream.frameRate = Double(renderSettings.fps)
//        stream.videoSettings.bitRateMode = .constant
//        rtmpStream.sessionPreset = .hd1920x1080
        rtmpStream.sessionPreset = .hd1920x1080
//        let bitrate = 6800 * 1000 // 6800 Kbps in bps
        
        rtmpStream.videoSettings = VideoCodecSettings(
            videoSize: CGSize(width: renderSettings.width, height: renderSettings.height),
            bitRate: bitrate,
            // renderSettings.getDefaultBitrate(),
//            profileLevel: kVTProfileLevel_H264_Baseline_5_2 as String,
//            profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel as String,
            profileLevel: kVTProfileLevel_H264_Main_AutoLevel as String,
            scalingMode: .trim,
            bitRateMode: .constant,
            maxKeyFrameIntervalDuration: 2
        )
        
        rtmpStream.audioSettings.bitRate = 128_000
        
//        rtmpStream.bitrateStrategy = VideoAdaptiveNetBitRateStrategy(mamimumVideoBitrate: VideoCodecSettings.default.bitRate)
    }
    
    public func startStreaming() {
        guard !isStreaming else { return }
        
        for (index, rtmpStream) in rtmpStreams.enumerated() {
            let streamKey = renderSettings.livestreamSettings![index].streamKey
            rtmpStream.fcPublishName = streamKey
            rtmpConnections[index].connect(renderSettings.livestreamSettings![index].rtmpConnection)
            rtmpStream.publish(streamKey)
        }
        
        isStreaming = true
        // resetFrameRateLogging()
    }
    
    public func stopStreaming() {
        guard isStreaming else { return }
        
        for rtmpStream in rtmpStreams {
            rtmpStream.close()
        }
        for rtmpConnection in rtmpConnections {
            rtmpConnection.close()
        }
        
        isStreaming = false
    }
    
    public func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isStreaming else { return }
       
        for rtmpStream in rtmpStreams {
            rtmpStream.append(sampleBuffer)
        }
        
        // logFrameRate()
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        // Handle RTMP status
        print("RTMP STATUS", notification)
    }
    
    @objc private func rtmpErrorHandler(_ notification: Notification) {
        print("RTMP ERROR", notification)
        // Handle RTMP error
    }
    
    private func resetFrameRateLogging() {
        frameCount = 0
        startTime = Date()
    }
    
    private func logFrameRate() {
        frameCount += 1
        
        guard let startTime = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        if elapsedTime >= logInterval {
            let frameRate = Double(frameCount) / elapsedTime
            print("Current frame rate: \(frameRate) fps")
            resetFrameRateLogging()
        }
    }
}
