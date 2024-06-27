//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/21/24.
//

import AVFoundation
import Foundation
import SwiftUI

@MainActor
public func createStreamUIRecorder<Content: View>(
    fps: Int32,
    width: CGFloat,
    height: CGFloat,
    displayScale: CGFloat,
    captureDuration: Duration? = nil,
    saveVideoFile: Bool = true,
    livestreamSettings: [LivestreamSettings]? = nil,
    @ViewBuilder content: @escaping () -> Content
) -> Recorder {
    let renderSettings = RenderSettings(
        width: Int(width),
        height: Int(height),
        fps: fps,
        displayScale: displayScale,
        captureDuration: captureDuration,
        saveVideoFile: saveVideoFile,
        livestreamSettings: livestreamSettings
    )

    let recorder = Recorder(renderSettings: renderSettings)

    let contentView = AnyView(content())

    recorder.setRenderer(view: contentView)

    return recorder
}
