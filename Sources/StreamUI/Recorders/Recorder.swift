import AVFoundation
import HaishinKit
import Observation
import SwiftUI

@Observable
public class Recorder {
    public enum RecordingState {
        case idle, recording, paused, finished
    }

    public private(set) var state: RecordingState = .idle

    public var recordingTask: Task<Void, Error>?
    private let recordingCompletionContinuation = AsyncStream<Void>.makeStream()

    public var controlledClock: ControlledClock
    public let frameTimer: FrameTimer

    @MainActor public var renderer: ImageRenderer<SizedView<AnyView>>?

    private var videoRecorder: VideoRecorder
    public var audioRecorder: AudioRecorder
    public let rtmpStreaming: RTMPStreaming

    public var renderSettings: RenderSettings
    public var assetWriter: AVAssetWriter?

    public init(renderSettings: RenderSettings) {
        self.controlledClock = ControlledClock()
        self.frameTimer = FrameTimer(frameRate: Double(renderSettings.fps))

        self.renderSettings = renderSettings

        self.videoRecorder = VideoRecorder(renderSettings: renderSettings)
        self.audioRecorder = AudioRecorder(renderSettings: renderSettings, frameTimer: frameTimer)
        self.rtmpStreaming = RTMPStreaming(renderSettings: renderSettings)

        videoRecorder.setParentRecorder(self)
        audioRecorder.setParentRecorder(self)
    }

    @MainActor
    public func setRenderer(view: AnyView) {
        let viewWithEnv = AnyView(view.environment(\.recorder, self))
        renderer = ImageRenderer(
            content: SizedView(
                content: viewWithEnv,
                width: CGFloat(renderSettings.width),
                height: CGFloat(renderSettings.height)
            )
        )
    }

    @MainActor
    public func startRecording() {
        guard state == .idle else { return }

        state = .recording
        frameTimer.start()

//        controlledClock.start()
        setupRecording()
        startRecordingTask()
    }

    public func setupRecording() {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let outputURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

            videoRecorder.setupVideoInput()
            audioRecorder.setupAudioInput()

            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: CMTime.zero)

            videoRecorder.startProcessingQueue()
            audioRecorder.startRecording()
            rtmpStreaming.startStreaming()
        } catch {
            print("Error starting recording: \(error)")
        }
    }

    private func startRecordingTask() {
        recordingTask = Task {
            let clock = ContinuousClock()

            let totalFrames = calculateTotalFrames()
            let frameDuration = Duration.seconds(1) / Int(renderSettings.fps)

            var bar = ProgressBar(count: totalFrames)

            while !Task.isCancelled, self.frameTimer.frameCount < totalFrames {
                switch state {
                case .recording:
                    bar.resume()
                    let start = clock.now

                    await captureFrame()
                    let end = clock.now
                    let elapsed = end - start

                    await controlledClock.advance(by: frameDuration)
                    let sleepDuration = frameDuration - elapsed
                    bar.next()

                    if sleepDuration > .zero {
                        try await Task.sleep(for: sleepDuration)
                    } else {}

                case .paused:
                    bar.pause()
                    try await Task.sleep(for: frameDuration)

                case .finished, .idle:
                    break
                }
            }

            print("WE OUTTAHERE")

            videoRecorder.stopProcessingQueue()
            print("Finished capturing frames")
            await videoRecorder.waitForProcessingCompletion()
            print("Finished processing all frames")
            await finishRecording()
        }
    }

    func finishRecording() {
        print("FINISH recording")
        guard state != .idle else { return }

        audioRecorder.stopRecording()

        finishWriting()
        recordingCompletionContinuation.continuation.finish()
        state = .idle
    }

    public func pauseRecording() {
        guard state == .recording else { return }
        state = .paused
//        audioRecorder.pauseAudio()
    }

    public func resumeRecording() {
        guard state == .paused else { return }
        state = .recording
//        audioRecorder.resumeAudio()
    }

    public func stopRecording() {
        guard state == .recording || state == .paused else { return }
        state = .finished
        recordingTask?.cancel()

        audioRecorder.stopRecording()
        videoRecorder.stopProcessingQueue()

        Task {
            await videoRecorder.waitForProcessingCompletion()
            await finishRecording()
        }
    }

    public func waitForRecordingCompletion() async {
        for await _ in recordingCompletionContinuation.stream {}
        try? await Task.sleep(for: .seconds(1.0))
    }

    private func finishWriting() {
        print("finish writing")
        if renderSettings.saveVideoFile {
            assetWriter?.finishWriting {
                print("Recording finished and saved to \(String(describing: self.assetWriter?.outputURL))")
//                DispatchQueue.main.async {
//                    NSApplication.shared.terminate(nil)
//                }

                if let outputURL = self.assetWriter?.outputURL, let duration = self.renderSettings.captureDuration {
                    self.trimVideo(at: outputURL, to: duration) { trimmedURL in
                        print("Recording finished and saved to \(String(describing: trimmedURL))")
                    }
                }
            }
        }
    }

//    Audio

    public func loadAudio(from url: URL) async throws {
        pauseRecording()
        try await audioRecorder.loadAudio(from: url)
        resumeRecording()
    }

    public func playAudio(from url: URL) {
        audioRecorder.playAudio(from: url)
    }

    public func stopAudio() {
//        audioRecorder.stopAudio()
    }

    public func pauseAudio() {
//        audioRecorder.pauseAudio()
    }

    public func resumeAudio() {
//        audioRecorder.resumeAudio()
    }

//    Video

    @MainActor
    private func captureFrame() {
        guard let renderer = renderer else { return }
        renderer.scale = renderSettings.displayScale
        guard let cgImage = renderer.cgImage else { return }

        let frameTime = frameTimer.getCurrentFrameTime()

        videoRecorder.appendFrame(cgImage: cgImage, frameTime: frameTime)

        frameTimer.incrementFrame()
    }

    private func calculateTotalFrames() -> Int {
        if let captureDuration = renderSettings.captureDuration {
            return Int(captureDuration.components.seconds) * Int(renderSettings.fps)
        } else {
            return Int.max
        }
    }

    private func trimVideo(at url: URL, to duration: Duration, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: url)
        let startTime = CMTime.zero
        let endTime = CMTime(seconds: Double(duration.components.seconds), preferredTimescale: 600)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create export session")
            completion(nil)
            return
        }

        let trimmedOutputURL = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        exportSession.outputURL = trimmedOutputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Trimming completed successfully")
                completion(trimmedOutputURL)
            case .failed:
                print("Trimming failed: \(String(describing: exportSession.error))")
                completion(nil)
            case .cancelled:
                print("Trimming cancelled")
                completion(nil)
            default:
                break
            }
        }
    }
}
