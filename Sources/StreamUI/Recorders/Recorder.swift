import AVFoundation
import ConsoleKit
import HaishinKit
import Observation
import SwiftUI

@Observable
public class Recorder {
    public enum RecordingState {
        case idle, recording, paused, finished
    }

    private var pauseCounter: Int = 0

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

   private var hud: HUD

    public init(renderSettings: RenderSettings) {
        self.controlledClock = ControlledClock()
        self.frameTimer = FrameTimer(frameRate: Double(renderSettings.fps))

        self.renderSettings = renderSettings
       self.hud = HUD()

        self.videoRecorder = VideoRecorder(renderSettings: renderSettings)
        self.audioRecorder = AudioRecorder(renderSettings: renderSettings, frameTimer: frameTimer)
        self.rtmpStreaming = RTMPStreaming(renderSettings: renderSettings)

        videoRecorder.setParentRecorder(self)
        audioRecorder.setParentRecorder(self)
       hud.setRecorder(recorder: self)
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

        setupRecording()
        startRecordingTask()
    }

    public func setupRecording() {
        do {
            assetWriter = try AVAssetWriter(outputURL: renderSettings.tempOutputURL, fileType: .mp4)

            videoRecorder.setupVideoInput()
            audioRecorder.setupAudioInput()

            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: CMTime.zero)

            videoRecorder.startProcessingQueue()
            rtmpStreaming.startStreaming()
        } catch {
            LoggerHelper.shared.error("Error starting recording: \(error)")
        }
    }

    private func startRecordingTask() {
        recordingTask = Task {
            let clock = ContinuousClock()

            let totalFrames = calculateTotalFrames()
            let frameDuration = Duration.seconds(1) / Int(renderSettings.fps)

            while !Task.isCancelled, state != .finished, self.frameTimer.frameCount < totalFrames {
                switch state {
                case .recording:
                    let start = clock.now

                    await captureFrame()

                    await controlledClock.advance(by: frameDuration)
                    let end = clock.now
                    let elapsed = end - start
                    let sleepDuration = frameDuration - elapsed

                    if sleepDuration > .zero {
//                        try await Task.sleep(for: .seconds(0.1))
                        try await Task.sleep(for: sleepDuration)
//                        try await Task.sleep(for: frameDuration)
                    }
                   self.hud.render()

                case .paused:
                   self.hud.render()
                    try await Task.sleep(for: frameDuration)

                case .finished, .idle:
                    break
                }
            }

           self.hud.render()
            await finishRecording()
        }
    }

    func finishRecording() async {
        videoRecorder.stopProcessingQueue()
        await videoRecorder.waitForProcessingCompletion()
        audioRecorder.stopRecording()

        await finishWriting()
    }

    public func pauseRecording() {
        pauseCounter += 1
        guard state == .recording else { return }
        state = .paused
        audioRecorder.pauseAllAudio()
    }

    public func resumeRecording() {
        pauseCounter -= 1
        guard state == .paused else { return }
        if pauseCounter == 0, state == .paused {
            state = .recording
            audioRecorder.resumeAllAudio()
        }
    }

    public func stopRecording() {
        guard state == .recording || state == .paused else { return }
        audioRecorder.stopRecording()
        state = .finished
    }

    public func waitForRecordingCompletion() async {
        for await _ in recordingCompletionContinuation.stream {}
    }

    private func finishWriting() async {
        guard renderSettings.saveVideoFile else {
            recordingCompletionContinuation.continuation.finish()
            return
        }

        await assetWriter?.finishWriting()

        guard let tempOutputURL = assetWriter?.outputURL else {
            LoggerHelper.shared.error("No output url")
            recordingCompletionContinuation.continuation.finish()
            return
        }

        if let outputURL = assetWriter?.outputURL, let duration = renderSettings.captureDuration {
            if let trimmedURL = await trimVideo(at: outputURL, to: duration) {
                try? FileManager.default.removeItem(at: tempOutputURL)
            }
        } else {
            try? FileManager.default.moveItem(at: tempOutputURL, to: renderSettings.outputURL)
        }

        recordingCompletionContinuation.continuation.finish()
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

    public func stopAudio(from url: URL) {
        audioRecorder.stopAudio(from: url)
    }

    public func pauseAudio(from url: URL) {
        audioRecorder.pauseAudio(from: url)
    }

    public func resumeAudio(from url: URL) {
        audioRecorder.resumeAudio(from: url)
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

    public func calculateTotalFrames() -> Int {
        if let captureDuration = renderSettings.captureDuration {
            return Int(captureDuration.components.seconds) * Int(renderSettings.fps)
        } else {
            return Int.max
        }
    }

    private func trimVideo(at url: URL, to duration: Duration) async -> URL? {
        let asset = AVAsset(url: url)
        let startTime = CMTime.zero
        let endTime = CMTime(seconds: Double(duration.components.seconds), preferredTimescale: 600)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            LoggerHelper.shared.error("Error trimming video - cant AVAssetExportSession")
            return nil
        }

        let trimmedOutputURL = renderSettings.outputURL
        exportSession.outputURL = trimmedOutputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)

        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: trimmedOutputURL)
                case .failed:
                    LoggerHelper.shared.error("Trimming failed: \(String(describing: exportSession.error))")
                    continuation.resume(returning: nil)
                case .cancelled:
                    LoggerHelper.shared.error("Trimming cancelled")
                    continuation.resume(returning: nil)
                default:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
