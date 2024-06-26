//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/16/24.
//

import AppKit
import AVFoundation

public struct LivestreamSettings {
    public var rtmpConnection: String
    public var streamKey: String
    public var profileLevel: String?
    public var bitRate: Int?

    public init(rtmpConnection: String, streamKey: String, profileLevel: String? = nil, bitRate: Int? = nil) {
        self.rtmpConnection = rtmpConnection
        self.streamKey = streamKey
        self.profileLevel = profileLevel
        self.bitRate = bitRate
    }
}

public struct RenderSettings {
    public var width: Int
    public var height: Int
    public var fps: Int32
    public var displayScale: CGFloat
    public var captureDuration: Duration?

    public var avCodecKey = AVVideoCodecType.h264
    public var saveVideoFile: Bool
    public var videoFilenameExt = "mp4"
    public var tempDirectoryURL: URL
    public var videoFilename: String

    public var livestreamSettings: [LivestreamSettings]?

    public init(
        width: Int,
        height: Int,
        fps: Int32,
        displayScale: CGFloat,
        captureDuration: Duration?,
        saveVideoFile: Bool = true,
        livestreamSettings: [LivestreamSettings]?
    ) {
        self.width = width
        self.height = height
        self.fps = fps
        self.captureDuration = captureDuration
        self.displayScale = displayScale
        self.livestreamSettings = livestreamSettings
        self.saveVideoFile = saveVideoFile

        self.videoFilename = "stream_ui_video_\(UUID().uuidString)"

        self.tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Failed to create temporary directory: \(error)")
        }
    }

    var outputURL: URL? {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
    }

    func getDefaultBitrate() -> Int {
        let numOfPixels = width * height
        switch numOfPixels {
        case 0 ... 102_240: return 800_000 // for 4/3 and 16/9 240p
        case 102_241 ... 230_400: return 1_000_000 // for 16/9 360p
        case 230_401 ... 409_920: return 1_300_000 // for 4/3 and 16/9 480p
        case 409_921 ... 921_600: return 2_000_000 // for 4/3 600p, 4/3 768p and 16/9 720p
        default: return 3_000_000 // for 16/9 1080p
        }
    }

    func getDefaultKeyframeInterval() -> Int32 {
        // Default to a keyframe every 2 seconds, but cap at 60 frames
        return min(fps * 2, 60)
    }
}
