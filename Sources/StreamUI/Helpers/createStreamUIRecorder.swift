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
    // Function to get the type name of the view
    func getTypeName(of view: Content) -> String {
        let mirror = Mirror(reflecting: view)
        return String(describing: mirror.subjectType)
    }

    let view = content()
    let viewTypeName = getTypeName(of: view)

    print("Type name", viewTypeName)

    let renderSettings = RenderSettings(
        name: viewTypeName,
        width: Int(width),
        height: Int(height),
        fps: fps,
        displayScale: displayScale,
        captureDuration: captureDuration,
        saveVideoFile: saveVideoFile,
        livestreamSettings: livestreamSettings
    )

    let recorder = Recorder(renderSettings: renderSettings)

    let contentView = AnyView(view)

    recorder.setRenderer(view: contentView)

    return recorder
}
