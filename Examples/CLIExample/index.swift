import AppKit
import ArgumentParser
import Foundation
import StreamUI
import SwiftUI
import VideoViews

// @Observable
// class StreamUISettings {
//    var fps: Int32 = 30
//    var width: CGFloat = 1080
//    var height: CGFloat = 1920
//    var captureDuration: Int = 20
//    var saveVideoFile: Bool = true
//
//    var livestreamSettings: [LivestreamSettings] = []
// }
//
//// Define the command line arguments
// struct StreamUICLIArgs: ParsableArguments {
//    @Option(help: "Frames per second")
//    var fps: Int
//
//    @Option(help: "Width of the video")
//    var width: Int
//
//    @Option(help: "Height of the video")
//    var height: Int
//
//    @Option(help: "Capture duration in seconds")
//    var captureDuration: Int
//
//    @Flag(help: "Save video file")
//    var saveVideoFile: Bool = false
//
//    @Option(help: "RTMP connection URL")
//    var rtmpConnection: String?
//
//    @Option(help: "Stream key")
//    var streamKey: String?
// }
//
// extension StreamUICLIArgs {
//    func update(_ settings: StreamUISettings) {
//        settings.fps = Int32(fps)
//        settings.width = CGFloat(width)
//        settings.height = CGFloat(height)
//
//        settings.captureDuration = captureDuration
//        settings.saveVideoFile = saveVideoFile
//
//        if let rtmpConnection = rtmpConnection, let streamKey = streamKey {
//            let livestreamSettings = LivestreamSettings(
//                rtmpConnection: rtmpConnection,
//                streamKey: streamKey
//            )
//            settings.livestreamSettings.append(livestreamSettings)
//        }
//    }
// }
//
// @main
// struct CLIExample: App {
//    @Environment(\.displayScale) private var displayScale
//
//    @State private var settings: StreamUISettings = {
//        let settings = StreamUISettings()
//        if CommandLine.argc > 1 {
//            do {
//                let args = try StreamUICLIArgs.parse()
//                args.update(settings)
//            } catch {
//                print("Error: Could not parse arguments")
//                print(CommandLine.arguments.dropFirst().joined(separator: " "))
//                print(StreamUICLIArgs.helpMessage())
//                exit(1) // Exit if argument parsing fails
//            }
//        } else {
//            settings.fps = 30
//            settings.width = 1080
//            settings.height = 1920
//            settings.captureDuration = 15
//            settings.saveVideoFile = true
//            settings.livestreamSettings = [
//                .init(rtmpConnection: "rtmp://localhost/live", streamKey: "streamKey")
//            ]
//        }
//        return settings
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            StreamUI(
//                fps: settings.fps,
//                width: settings.width,
//                height: settings.height,
//                displayScale: displayScale,
////                captureDuration: .seconds(settings.captureDuration),
//                saveVideoFile: settings.saveVideoFile,
//                livestreamSettings: settings.livestreamSettings
//            ) {
//                BasicCounterView(initialCounter: 0)
////                SpriteKitTestView()
////                SimpleWebView()
////                VideoTestView()
////                RandomSwiftUIComponentsTestView()
//            }
//        }
//    }
// }

//
//
// Or if you don't want the View to see the rendering with controls you can:
//
//

@main
enum CLIExample {
    static func main() async throws {
        print("huhu")
        let recorder = createStreamUIRecorder(
            fps: 30,
            width: 1080,
            height: 1920,
            displayScale: 2.0,
            captureDuration: .seconds(7),
            saveVideoFile: true
        ) {
//            BasicCounterView(initialCounter: 0)
//            VideoTestView()
            ImageTestView()
//            SoundTestView()
//            SpriteKitTestView()
//            SceneKitTestView()
        }

        let controlledClock = recorder.controlledClock

        recorder.startRecording()

//        try await Task.sleep(for: .seconds(5))
        ////        try await controlledClock.sleep(for: 5.0)
//        recorder.pauseRecording()
//        try await Task.sleep(for: .seconds(10))
        ////        try await controlledClock.sleep(for: 10.0)
//        recorder.resumeRecording()
//        recorder.stopRecording()
//        try await Task.sleep(for: .seconds(2))
//        recorder.resumeRecording()

        // Wait for the recording to complete
        await recorder.waitForRecordingCompletion()

//        while recorder.isRecording {
//            print("while recording")
//            try await Task.sleep(for: .seconds(5))
//            print("waited five secs")
//            recorder.isPaused.toggle()
//            try await Task.sleep(for: .seconds(2))
//            recorder.isPaused.toggle()
//        }

//        try await Task.sleep(for: .seconds(1.0))
    }
}
