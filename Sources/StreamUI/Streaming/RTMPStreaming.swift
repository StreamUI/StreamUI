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
        rtmpStream.videoSettings.videoSize = CGSize(width: CGFloat(renderSettings.width), height: CGFloat(renderSettings.height))
        rtmpStream.videoSettings.profileLevel = streamSettings.profileLevel ?? kVTProfileLevel_H264_Main_AutoLevel as String
        rtmpStream.videoSettings.bitRate = streamSettings.bitRate ?? renderSettings.getDefaultBitrate()
        rtmpStream.videoSettings.maxKeyFrameIntervalDuration = 2
        rtmpStream.videoSettings.scalingMode = .trim
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
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        // Handle RTMP status
    }
    
    @objc private func rtmpErrorHandler(_ notification: Notification) {
        // Handle RTMP error
    }
}
