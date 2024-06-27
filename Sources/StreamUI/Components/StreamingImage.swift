//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import Nuke
import SwiftUI

public enum ScaleType {
    case fit, fill
}

public struct StreamingImage: View {
    @Environment(\.recorder) private var recorder

    let url: URL?
    private let scaleType: ScaleType
    @State private var image: NSImage? = nil

    public init(url: URL?, scaleType: ScaleType = .fill) {
        self.url = url
        self.scaleType = scaleType
    }

    public var body: some View {
        VStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: scaleType == .fill ? .fill : .fit)
                    .onAppear {
                        recorder?.resumeRecording()
                    }
            }
        }
        .onAppear {
            recorder?.pauseRecording()
            Task {
                await loadImage()
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        do {
            self.image = try await PreloadManager.shared.image(from: url)
        } catch {
            LoggerHelper.shared.error("Failed to preload image: \(error)")
        }
    }
}
