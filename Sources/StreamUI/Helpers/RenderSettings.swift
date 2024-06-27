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
    public var name: String
    public var width: Int
    public var height: Int
    public var fps: Int32
    public var displayScale: CGFloat
    public var captureDuration: Duration?

    public var avCodecKey = AVVideoCodecType.h264
    public var saveVideoFile: Bool

    public var videoFilenameExt = "mp4"
    public var videosDirectoryURL: URL
    public var tempDirectoryURL: URL
    public var videoDirectoryURL: URL

    public var videoFilename: String

    public var livestreamSettings: [LivestreamSettings]?

    public init(
        name: String = "streamui_video",
        width: Int,
        height: Int,
        fps: Int32,
        displayScale: CGFloat,
        captureDuration: Duration?,
        saveVideoFile: Bool = true,
        livestreamSettings: [LivestreamSettings]?
    ) {
        self.name = name
        self.width = width
        self.height = height
        self.fps = fps
        self.captureDuration = captureDuration
        self.displayScale = displayScale
        self.livestreamSettings = livestreamSettings
        self.saveVideoFile = saveVideoFile

        // Generate a short timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        // Create the video file name using the name and timestamp
        self.videoFilename = "\(name)_\(timestamp)"

        // Get the app's container directory
        guard let containerURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Failed to get app container directory")
        }

        // Create a "StreamUI" folder in the app's container
        let streamUIDirectoryURL = containerURL.appendingPathComponent("StreamUI", isDirectory: true)
        self.videosDirectoryURL = streamUIDirectoryURL.appendingPathComponent("videos", isDirectory: true)
        self.tempDirectoryURL = videosDirectoryURL.appendingPathComponent(".tmp", isDirectory: true)
        self.videoDirectoryURL = videosDirectoryURL.appendingPathComponent(name)

        do {
            try FileManager.default.createDirectory(at: videosDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: videoDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("failed")
            fatalError("Failed to create directories: \(error)")
        }
    }

    var outputURL: URL {
        return videoDirectoryURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
    }

    var tempOutputURL: URL {
        tempDirectoryURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
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
