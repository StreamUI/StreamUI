import AppKit
import Foundation
import SwiftUI

public struct StreamUI<Content: View>: View {
    @State public var recorder: Recorder
    @State private var windowSize: CGSize = .zero
    @State private var isVideoSaved: Bool = false
    @State private var isAnimating = false

    @MainActor
    public init(
        fps: Int32,
        width: CGFloat,
        height: CGFloat,
        displayScale: CGFloat,
        captureDuration: Duration? = nil,
        saveVideoFile: Bool = true,
        livestreamSettings: [LivestreamSettings]? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        func getTypeName(of view: Content) -> String {
            let mirror = Mirror(reflecting: view)
            return String(describing: mirror.subjectType)
        }

        let view = content()
        let viewTypeName = getTypeName(of: view)

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

        let contentView = AnyView(view)

        _recorder = State(wrappedValue: Recorder(renderSettings: renderSettings))

        recorder.setRenderer(view: contentView)
    }

    var borderColor: Color {
        if recorder.state == .recording {
            return Color.red
        }

        return Color.gray.opacity(0.3)
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Content area
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)

                    GeometryReader { contentGeometry in
                        if let content = recorder.renderer?.content {
                            let renderWidth = CGFloat(recorder.renderSettings.width)
                            let renderHeight = CGFloat(recorder.renderSettings.height)
                            let maxWidth = contentGeometry.size.width * 0.90
                            let maxHeight = contentGeometry.size.height * 0.90
                            let widthRatio = maxWidth / renderWidth
                            let heightRatio = maxHeight / renderHeight
                            let scaleFactor = min(widthRatio, heightRatio, 1.0)

                            let scaledWidth = renderWidth * scaleFactor
                            let scaledHeight = renderHeight * scaleFactor

                            content
                                .frame(width: renderWidth, height: renderHeight)
                                .scaleEffect(scaleFactor)
                                .frame(width: scaledWidth, height: scaledHeight)
                                .border(borderColor)
                                .clipped()
//                                .border(recorder.isRecording && !recorder.isPaused ? Color.red : Color.gray.opacity(0.3), width: 2)
                                .position(x: contentGeometry.size.width / 2, y: contentGeometry.size.height / 2)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.8)

                // Sidebar
                VStack {
                    VStack(alignment: .center, spacing: 10) {
                        Text("~ StreamUI")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.black)

                        HStack(alignment: .center, spacing: 25) {
                            SocialButton(imageName: "discord", url: "https://discord.com")
                            SocialButton(imageName: "x", url: "https://twitter.com")
                            SocialButton(imageName: "github", url: "https://github.com")
                        }
                    }
                    .padding(.top)

                    RecordingIndicator(state: recorder.state, isLive: recorder.renderSettings.livestreamSettings != nil)
                        .padding(.top)

                    Spacer()

                    if let duration = recorder.renderSettings.captureDuration {
                        ProgressView(value: Double(recorder.frameTimer.frameCount) / Double(Double(duration.components.seconds) * Double(recorder.renderSettings.fps)))
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .padding()
                    }

                    VStack(spacing: 10) {
                        Text(recorder.state == .recording || recorder.state == .paused ? "Stop" : "Start")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .onTapGesture {
                                if recorder.state == .recording || recorder.state == .paused {
                                    recorder.stopRecording()
                                    Task {
                                        await recorder.waitForRecordingCompletion()
                                    }
                                } else {
                                    recorder.startRecording()
                                }
                            }

                        Text(recorder.state == .paused ? "Resume" : "Pause")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(recorder.state == .recording ? Color.orange : Color.gray)
                            .cornerRadius(8)
                            .onTapGesture {
                                if recorder.state == .paused {
                                    recorder.resumeRecording()
                                } else {
                                    recorder.pauseRecording()
                                }
                            }

                        if isVideoSaved {
                            Text("Open Video")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                                .onTapGesture {
                                    let url = recorder.renderSettings.outputURL
                                    NSWorkspace.shared.open(url)
                                }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
                .frame(width: geometry.size.width * 0.2)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            }
        }
        .frame(width: NSScreen.main?.visibleFrame.width ?? 800 * 0.9,
               height: NSScreen.main?.visibleFrame.height ?? 600 * 0.9)
        .onChange(of: recorder.state) { recorderState in
            if recorderState == .finished {
                isVideoSaved = recorder.renderSettings.saveVideoFile
            }
            isAnimating = recorderState == .recording
        }
//        .onChange(of: recorder.isPaused) { isPaused in
//            isAnimating = recorder.isRecording && !isPaused
//        }
    }
}

struct SocialButton: View {
    let imageName: String
    let url: String

    var body: some View {
        Image(packageResource: imageName, ofType: "png")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 30)
            .onTapGesture {
                if let url = URL(string: url) {
                    NSWorkspace.shared.open(url)
                }
            }
    }
}

struct RecordingIndicator: View {
    let state: Recorder.RecordingState
    let isLive: Bool
    @State private var isAnimating = false

    var stateText: String {
        if state == .recording {
            return "Recording"
        } else if state == .paused {
            return "Paused"
        }
        return "Finished"
    }

    var borderColor: Color {
        if state == .recording {
            return Color.red
        }

        return Color.gray.opacity(0.3)
    }

    var body: some View {
        HStack {
            Circle()
                .fill(borderColor)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(state == .recording ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isAnimating)

            if isLive {
                Text("LIVE")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }

            Text(stateText)
                .foregroundColor(.black)
                .font(.caption)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
        .onAppear {
            isAnimating = state == .recording
        }
        .onChange(of: state) { newState in
            isAnimating = newState == .recording
        }
    }
}

//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

// import AppKit
// import Foundation
// import Logging
// import SwiftUI
//
//// @MainActor
// public struct StreamUI<Content: View>: View {
//    @State public var recorder: Recorder
//
//    @MainActor
//    public init(
//        fps: Int32,
//        width: CGFloat,
//        height: CGFloat,
//        displayScale: CGFloat,
//        captureDuration: Duration? = nil,
//        saveVideoFile: Bool = true,
//        livestreamSettings: [LivestreamSettings]? = nil,
//        @ViewBuilder content: @escaping () -> Content
//    ) {
//        let renderSettings = RenderSettings(
//            width: Int(width),
//            height: Int(height),
//            fps: fps,
//            displayScale: displayScale,
//            captureDuration: captureDuration,
//            saveVideoFile: saveVideoFile,
//            livestreamSettings: livestreamSettings
//        )
//
//        let contentView = AnyView(content())
//
//        _recorder = State(wrappedValue: Recorder(renderSettings: renderSettings))
//
//        recorder.setRenderer(view: contentView)
//    }
//
//    public var body: some View {
//        recorder.renderer?.content
//            .onAppear {
//                print("Onappear start recording")
//                recorder.startRecording()
//            }
//            .onDisappear {
//                print("done recording")
//                recorder.stopRecording()
//            }
////            .onChange(of: recorder.isRecording) { isRecording in
////                if !isRecording {
////                    NSApplication.shared.terminate(nil)
////                }
////            }
//    }
// }
