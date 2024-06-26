import AVFoundation
import Combine
import Foundation

enum AudioRecorderError: Error {
    case failedToLoadAudio(Error)
}

let hz = 44100.0

public class AudioRecorder {
    public var renderSettings: RenderSettings
    weak var parentRecorder: Recorder?
    private var audioInput: AVAssetWriterInput?

    private var audioEngine = AVAudioEngine()
    private var playerNodes: [URL: AVAudioPlayerNode] = [:]
    private var audioFiles: [URL: AVAudioFile] = [:]
    private var audioBuffers: [URL: AVAudioPCMBuffer] = [:]
    private var currentAudioBuffer: AVAudioPCMBuffer?

    private var cancellables = Set<AnyCancellable>()

    private var audioFormatDescription: CMAudioFormatDescription?
    private var reusableAudioBuffer: UnsafeMutablePointer<Float>?
    private var reusableAudioBufferSize: Int = 0

    private let captureQueue = DispatchQueue(label: "com.yourapp.captureQueue", qos: .userInitiated)
    private let audioStream = AudioStream()
    private var frameTimer: FrameTimer?
    public var audioBuffersByTime: [CMTime: AVAudioPCMBuffer] = [:]

    public init(renderSettings: RenderSettings, frameTimer: FrameTimer) {
        self.renderSettings = renderSettings
        self.frameTimer = frameTimer
        setupAudioEngine()
    }

    func setParentRecorder(_ parentRecorder: Recorder) {
        self.parentRecorder = parentRecorder
    }

    func setupAudioInput() {
        guard let assetWriter = parentRecorder?.assetWriter else {
            print("no asset writer")
            return
        }

        let audioFormatSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: hz,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioFormatSettings)
        audioInput?.expectsMediaDataInRealTime = true

        if let audioInput = audioInput, assetWriter.canAdd(audioInput) {
            print("Set up audio input")
            assetWriter.add(audioInput)
        } else {
            print("Cannot set up audio input. Asset writer status: \(assetWriter.status). Error: \(String(describing: assetWriter.error))")
        }
    }

    private func setupAudioEngine() {
        let mainMixerNode = audioEngine.mainMixerNode
        let outputFormat = mainMixerNode.outputFormat(forBus: 0)

        let silentNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0 ..< Int(frameCount) {
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = 0.0
                }
            }
            return noErr
        }

        audioEngine.attach(silentNode)
        audioEngine.connect(silentNode, to: mainMixerNode, format: outputFormat)

        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("Audio engine started successfully")
            Task {
                await self.processAudioSamples()
            }
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    private func processCapturedAudio(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard parentRecorder?.state == .recording else {
            return
        }
//        audioStream.enqueue(buffer, withTime: time.audioTimeStamp.mSampleTime)
    }

    private func processAudioSamples() async {
        for await audioSample in audioStream.stream {
            await appendAudioBuffer(audioSample.buffer, at: audioSample.time)
        }
    }

    public func addToStream(_ buffer: AVAudioPCMBuffer, at time: CMTime) {
        audioStream.enqueue(buffer, withTime: time)
    }

    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: CMTime) {
        guard parentRecorder?.state == .recording else {
            print("not recording audio")
            return
        }

        guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData else {
            return
        }

        if audioFormatDescription == nil {
            let status = CMAudioFormatDescriptionCreate(
                allocator: kCFAllocatorDefault,
                asbd: buffer.format.streamDescription,
                layoutSize: 0,
                layout: nil,
                magicCookieSize: 0,
                magicCookie: nil,
                extensions: nil,
                formatDescriptionOut: &audioFormatDescription
            )
            if status != noErr {
                return
            }
        }

        let dataLength = Int(buffer.frameLength) * MemoryLayout<Float32>.size * Int(buffer.format.channelCount)
        guard let channelData = buffer.floatChannelData else {
            return
        }

        var blockBuffer: CMBlockBuffer?
        let blockBufferStatus = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: channelData[0],
            blockLength: dataLength,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataLength,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        guard blockBufferStatus == kCMBlockBufferNoErr else {
            return
        }

        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = time

        let sampleBufferStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: audioFormatDescription!,
            sampleCount: CMItemCount(buffer.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )

        guard sampleBufferStatus == noErr else {
            return
        }

        if let sampleBuffer = sampleBuffer {
            if !audioInput.append(sampleBuffer) {
                print("[AUDIO] Failed to append audio sample buffer")
            }
            parentRecorder?.rtmpStreaming.appendSampleBuffer(sampleBuffer)
        }
    }

    func loadAudio(from url: URL) async throws {
        let localURL = try await PreloadManager.shared.preloadMedia(from: url)

        do {
            let audioFile = try AVAudioFile(forReading: localURL)
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
            try audioFile.read(into: audioBuffer!)
            audioFiles[url] = audioFile
            audioBuffers[url] = audioBuffer
        } catch {
            throw AudioRecorderError.failedToLoadAudio(error)
        }
    }

    public func playAudio(from url: URL) {
        guard let audioBuffer = audioBuffers[url] else {
            print("No audio loaded for \(url)")
            return
        }

        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        playerNodes[url] = playerNode

        let commonFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: commonFormat)

        guard let convertedBuffer = convertBuffer(audioBuffer, to: commonFormat) else {
            print("Failed to convert audio buffer")
            return
        }

        let bufferSize = AVAudioFrameCount(0.1 * hz) // 100 ms buffer
        playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: commonFormat) { [weak self] buffer, when in
            if let frameTime = self?.frameTimer?.getCurrentFrameTime() {
                self?.addToStream(buffer, at: when.toCMTime())
            }
        }

        // Schedule buffer in chunks
        let chunkSize = AVAudioFrameCount(0.5 * hz) // 500 ms chunks
        var startFrame: AVAudioFramePosition = 0

        while startFrame < AVAudioFramePosition(convertedBuffer.frameLength) {
            let framesToPlay = min(chunkSize, AVAudioFrameCount(convertedBuffer.frameLength) - AVAudioFrameCount(startFrame))
            if let chunk = copyBuffer(convertedBuffer, fromFrame: AVAudioFrameCount(startFrame), frameCount: framesToPlay) {
                playerNode.scheduleBuffer(chunk)
            }
            startFrame += AVAudioFramePosition(framesToPlay)
        }

        playerNode.play()
        print("Playing audio from \(url)")
    }

    // Add this helper function to copy a portion of an AVAudioPCMBuffer
    private func copyBuffer(_ buffer: AVAudioPCMBuffer, fromFrame start: AVAudioFrameCount, frameCount: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameCount) else {
            return nil
        }

        let channelCount = buffer.format.channelCount
        let sampleSize = buffer.format.streamDescription.pointee.mBytesPerFrame / UInt32(channelCount)

        for channel in 0 ..< channelCount {
            guard let src = buffer.floatChannelData?[Int(channel)],
                  let dst = newBuffer.floatChannelData?[Int(channel)]
            else {
                continue
            }

            dst.assign(from: src.advanced(by: Int(start)), count: Int(frameCount))
        }

        newBuffer.frameLength = frameCount
        return newBuffer
    }

    public func stopAudio(from url: URL) {
        guard let playerNode = playerNodes[url] else { return }
        playerNode.stop()
        playerNode.removeTap(onBus: 0)
        audioEngine.detach(playerNode)
        playerNodes.removeValue(forKey: url)
    }

    func pauseAudio(from url: URL) {
        guard let playerNode = playerNodes[url] else { return }
        playerNode.pause()
    }

    func resumeAudio(from url: URL) {
        guard let playerNode = playerNodes[url] else { return }
        playerNode.play()
    }

    func stopAllAudio() {
        for playerNode in playerNodes.values {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        playerNodes.removeAll()
    }

    func startRecording() {}

    func stopRecording() {
        audioEngine.stop()
        for playerNode in playerNodes.values {
            playerNode.stop()
        }
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            print("Failed to create AVAudioConverter")
            return nil
        }

        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity)!
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        do {
            try converter.convert(to: convertedBuffer, error: nil, withInputFrom: inputBlock)
        } catch {
            print("Error converting buffer: \(error)")
            return nil
        }

        return convertedBuffer
    }
}

// import AVFoundation
// import SwiftUI
//
// enum AudioRecorderError: Error {
//    case failedToLoadAudio(Error)
// }
//
//// let hz = 33500.0
// let hz = 44100.0
//
// public class AudioRecorder {
//    public var renderSettings: RenderSettings
//    weak var parentRecorder: Recorder?
//    private var audioInput: AVAssetWriterInput?
//
//    private var audioEngine = SharedAudioManager.shared.audioEngine
//    private var playerNode = SharedAudioManager.shared.playerNode
//    private var audioFiles: [URL: AVAudioFile] = [:]
//    private var audioBuffers: [URL: AVAudioPCMBuffer] = [:]
//    private var currentAudioBuffer: AVAudioPCMBuffer?
//
//    private var audioFormatDescription: CMAudioFormatDescription?
//    private var reusableAudioBuffer: UnsafeMutablePointer<Float>?
//    private var reusableAudioBufferSize: Int = 0
//
////    private let captureQueue = DispatchQueue(label: "com.yourapp.captureQueue", qos: .userInitiated)
//    private let audioStream = AudioStream()
//    private var frameTimer: FrameTimer?
//    public var audioBuffersByTime: [CMTime: AVAudioPCMBuffer] = [:]
//
//    public init(renderSettings: RenderSettings, frameTimer: FrameTimer) {
//        self.renderSettings = renderSettings
//        self.frameTimer = frameTimer
//        setupAudioEngine()
//    }
//
//    func setParentRecorder(_ parentRecorder: Recorder) {
//        self.parentRecorder = parentRecorder
//    }
//
//    func setupAudioInput() {
//        guard let assetWriter = parentRecorder?.assetWriter else {
//            print("no asset writer")
//            return
//        }
//
//        let audioFormatSettings: [String: Any] = [
//            AVFormatIDKey: kAudioFormatLinearPCM,
//            AVSampleRateKey: hz,
//            AVNumberOfChannelsKey: 2,
//            AVLinearPCMBitDepthKey: 16,
//            AVLinearPCMIsNonInterleaved: false,
//            AVLinearPCMIsFloatKey: false,
//            AVLinearPCMIsBigEndianKey: false
//        ]
//
//        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioFormatSettings)
//        audioInput?.expectsMediaDataInRealTime = true
//
//        if let audioInput = audioInput, assetWriter.canAdd(audioInput) {
//            print("Set up audio input")
//            assetWriter.add(audioInput)
//        } else {
//            print("Cannot set up audio input. Asset writer status: \(assetWriter.status). Error: \(String(describing: assetWriter.error))")
//        }
//    }
//
//    private func setupAudioEngine() {
//        audioEngine.attach(playerNode)
//        let format = AVAudioFormat(standardFormatWithSampleRate: hz, channels: 2)!
//        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
//        let tempDirectoryURL = FileManager.default.temporaryDirectory
//        let outputURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
//        let audioFile = try! AVAudioFile(forWriting: outputURL, settings: format.settings)
//
//        let bufferDurationSeconds = 0.25 // 100 ms
//        let bufferSize = AVAudioFrameCount(bufferDurationSeconds * hz)
//
//        var audioBufferCounter = 0 // Counter to track when to capture audio buffers
//        let framesPerBuffer = Int(Double(renderSettings.fps) * bufferDurationSeconds)
//
//        playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: playerNode.outputFormat(forBus: 0)) { buffer, _ in
//            guard self.parentRecorder?.state == .recording else {
//                print("not recording audio")
//                return
//            }
//
//            if let presentationTime = self.frameTimer?.getCurrentFrameTime() {
//                self.audioStream.enqueue(buffer, withTime: presentationTime)
//            }
//        }
//        Task {
//            await self.processAudioSamples()
//        }
//    }
//
//    private func processAudioSamples() async {
//        for await audioSample in audioStream.stream {
//            await appendAudioBuffer(audioSample.buffer, at: audioSample.time)
//        }
//    }
//
//    public func addToStream(_ buffer: AVAudioPCMBuffer, at time: CMTime) {
//        audioStream.enqueue(buffer, withTime: time)
//    }
//
//    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: CMTime) {
//        guard parentRecorder?.state == .recording else {
//            print("not recording audio")
//            return
//        }
//
//        guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData else {
//            return
//        }
//
//        if audioFormatDescription == nil {
//            let status = CMAudioFormatDescriptionCreate(
//                allocator: kCFAllocatorDefault,
//                asbd: buffer.format.streamDescription,
//                layoutSize: 0,
//                layout: nil,
//                magicCookieSize: 0,
//                magicCookie: nil,
//                extensions: nil,
//                formatDescriptionOut: &audioFormatDescription
//            )
//            if status != noErr {
//                return
//            }
//        }
//
//        let dataLength = Int(buffer.frameLength) * MemoryLayout<Float32>.size * Int(buffer.format.channelCount)
//        guard let channelData = buffer.floatChannelData else {
//            return
//        }
//
//        var blockBuffer: CMBlockBuffer?
//        let blockBufferStatus = CMBlockBufferCreateWithMemoryBlock(
//            allocator: kCFAllocatorDefault,
//            memoryBlock: channelData[0],
//            blockLength: dataLength,
//            blockAllocator: kCFAllocatorNull,
//            customBlockSource: nil,
//            offsetToData: 0,
//            dataLength: dataLength,
//            flags: 0,
//            blockBufferOut: &blockBuffer
//        )
//
//        guard blockBufferStatus == kCMBlockBufferNoErr else {
//            return
//        }
//
//        var sampleBuffer: CMSampleBuffer?
//        var timingInfo = CMSampleTimingInfo()
//        timingInfo.presentationTimeStamp = time
//
//        let sampleBufferStatus = CMSampleBufferCreate(
//            allocator: kCFAllocatorDefault,
//            dataBuffer: blockBuffer,
//            dataReady: true,
//            makeDataReadyCallback: nil,
//            refcon: nil,
//            formatDescription: audioFormatDescription!,
//            sampleCount: CMItemCount(buffer.frameLength),
//            sampleTimingEntryCount: 1,
//            sampleTimingArray: &timingInfo,
//            sampleSizeEntryCount: 0,
//            sampleSizeArray: nil,
//            sampleBufferOut: &sampleBuffer
//        )
//
//        guard sampleBufferStatus == noErr else {
//            return
//        }
//
//        if let sampleBuffer = sampleBuffer {
//            if !audioInput.append(sampleBuffer) {
//                print("[AUDIO] Failed to append audio sample buffer")
//            }
//            parentRecorder?.rtmpStreaming.appendSampleBuffer(sampleBuffer)
//        }
//    }
//
//    func loadAudio(from url: URL) async throws {
//        let localURL = try await PreloadManager.shared.preloadMedia(from: url)
//
//        do {
//            let audioFile = try AVAudioFile(forReading: localURL)
//            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
//            try audioFile.read(into: audioBuffer!)
//            audioFiles[url] = audioFile
//            audioBuffers[url] = audioBuffer
//        } catch {
//            throw AudioRecorderError.failedToLoadAudio(error)
//        }
//    }
//
//    func playAudio(from url: URL) {
//        guard let audioBuffer = audioBuffers[url] else {
//            print("No audio loaded for \(url)")
//            return
//        }
//        do {
//            try audioEngine.start()
//            playerNode.scheduleBuffer(audioBuffer, at: nil, options: [.loops], completionHandler: nil)
//            playerNode.play()
//        } catch {
//            print("Could not start audio playback: \(error)")
//        }
//    }
//
//    func stopAudio() {
//        playerNode.stop()
//        audioEngine.stop()
//    }
//
//    func pauseAudio() {
//        playerNode.pause()
//    }
//
//    func resumeAudio() {
//        playerNode.play()
//    }
//
//    func startRecording() {
//        guard let audioBuffer = currentAudioBuffer else { return }
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Could not start audio engine: \(error)")
//            return
//        }
//        playerNode.scheduleBuffer(audioBuffer, at: nil, options: [], completionHandler: nil)
//        playerNode.play()
//    }
//
//    func stopRecording() {
//        audioEngine.stop()
//        playerNode.stop()
//
//        if let audioInput = audioInput {
//            audioInput.markAsFinished()
//        }
//    }
// }
