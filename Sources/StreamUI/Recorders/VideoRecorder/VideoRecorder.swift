import AVFoundation
import CoreImage
import CoreVideo
import HaishinKit
import Metal
import SwiftUI
import VideoToolbox

class VideoRecorder {
    public var renderSettings: RenderSettings
    weak var parentRecorder: Recorder?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var pixelBufferTimes: [Double] = []

    private let frameStream = FrameStream()
    private var processingTask: Task<Void, Error>?

    private let processingCompletionContinuation = AsyncStream<Void>.makeStream()
    private var isProcessingComplete = false

    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }

    func setParentRecorder(_ parentRecorder: Recorder) {
        self.parentRecorder = parentRecorder
    }

    func setupVideoInput() {
        guard let assetWriter = parentRecorder?.assetWriter else { return }

        // Define compression properties
        let compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: renderSettings.getDefaultBitrate(),
            AVVideoMaxKeyFrameIntervalKey: 1, // Force keyframe at start
            AVVideoProfileLevelKey: AVVideoProfileLevelH264High41,
            AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC
        ]

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: renderSettings.width,
            AVVideoHeightKey: renderSettings.height,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferWidthKey as String: renderSettings.width,
            kCVPixelBufferHeightKey as String: renderSettings.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        if let videoInput = videoInput, assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        }
    }

    func startProcessingQueue() {
        processingTask = Task {
            for await videoFrame in frameStream.stream {
                guard !Task.isCancelled else { break }
//                let start = parentRecorder?.clock.now
                self.processFrame(cgImage: videoFrame.image, frameTime: videoFrame.time)
//                let end = parentRecorder?.clock.now
//                let elapsed = end! - start!
            }
            print("finished processing queue")
            isProcessingComplete = true

            processingCompletionContinuation.continuation.yield()
            processingCompletionContinuation.continuation.finish()
        }
    }

    func waitForProcessingCompletion() async {
        while !isProcessingComplete {
            try? await Task.sleep(for: .milliseconds(100))
        }
        for await _ in processingCompletionContinuation.stream {}
    }

    func stopProcessingQueue() {
        frameStream.finish()
    }

    public func appendFrame(cgImage: CGImage, frameTime: CMTime) {
        frameStream.enqueue(cgImage, withTime: frameTime)
    }

    public func processFrame(cgImage: CGImage, frameTime: CMTime) {
//        let startProcessTime = parentRecorder?.clock.now
        guard let pixelBuffer = pixelBufferFromCGImage(cgImage, width: renderSettings.width, height: renderSettings.height) else { return }
//        let endPixelBufferTime = parentRecorder?.clock.now
//        let pixelBufferElapsed = endPixelBufferTime! - startProcessTime!
//        pixelBufferTimes.append(Double(pixelBufferElapsed.inMilliseconds))
        if renderSettings.saveVideoFile {
            guard let assetWriter = parentRecorder?.assetWriter, assetWriter.status == .writing else { return }
            guard let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }
            guard let pixelBufferAdaptor = pixelBufferAdaptor else { return }
            pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
        }

        guard let sampleBuffer = createCMSampleBuffer(from: pixelBuffer, presentationTime: frameTime) else { return }

        parentRecorder?.rtmpStreaming.appendSampleBuffer(sampleBuffer)
    }
}
