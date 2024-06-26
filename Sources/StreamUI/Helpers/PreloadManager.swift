//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import AVFoundation
import Combine
import Foundation
import Nuke

class PreloadManager {
    static let shared = PreloadManager()
    
    private let imagePrefetcher: ImagePrefetcher
    private let dataCache: DataCache
    private let imagePipeline: ImagePipeline
    
    private init() {
        dataCache = try! DataCache(name: "live.ui.stream")
        
        var pipelineConfiguration = ImagePipeline.Configuration()
        pipelineConfiguration.isProgressiveDecodingEnabled = true
        pipelineConfiguration.dataLoader = DataLoader(configuration: .default)
        
        imagePipeline = ImagePipeline(configuration: pipelineConfiguration)
        imagePrefetcher = ImagePrefetcher(pipeline: imagePipeline)
    }
    
    // Preload images using Nuke
    func preloadImage(from url: URL) async throws {
        try await imagePipeline.image(for: url)
    }
    
    func image(from url: URL) async throws -> PlatformImage {
        return try await imagePipeline.image(for: url)
    }
    
    // Preload video or audio using URLSession
    func preloadMedia(from url: URL) async throws -> URL {
        let cachedFileURL = localFileURL(for: url)
        if FileManager.default.fileExists(atPath: cachedFileURL.path) {
            return cachedFileURL
        }
        
        let (localURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: localURL, to: cachedFileURL)
        return cachedFileURL
    }
    
    // Get local file URL for a cached file
    private func localFileURL(for url: URL) -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent(url.lastPathComponent)
    }
    
    // Function to preload any URL
    func preload(from url: URL) async throws {
        if url.isImage {
            try await preloadImage(from: url)
        } else {
            try await preloadMedia(from: url)
        }
    }
}

extension URL {
    var isImage: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
}
