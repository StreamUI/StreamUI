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
    private var playingAudioSources: Set<URL> = []

    private var audioFormatDescription: CMAudioFormatDescription?

    private let audioStream = AudioStream()
    private var frameTimer: FrameTimer?

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
            LoggerHelper.shared.error("No asset writer")
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
            assetWriter.add(audioInput)
        } else {
            LoggerHelper.shared.error("Cannot set up audio input. Asset writer status: \(assetWriter.status). Error: \(String(describing: assetWriter.error))")
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
            Task {
                await self.processAudioSamples()
            }
        } catch {
            LoggerHelper.shared.error("Error starting audio engine: \(error)")
        }
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
                LoggerHelper.shared.error("[AUDIO] Failed to append audio sample buffer")
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
            LoggerHelper.shared.error("No audio loaded for \(url)")
            return
        }

        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        playerNodes[url] = playerNode

        let commonFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: commonFormat)

        guard let convertedBuffer = convertBuffer(audioBuffer, to: commonFormat) else {
            LoggerHelper.shared.error("Failed to convert audio buffer")
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
        playingAudioSources.insert(url)
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
        playingAudioSources.remove(url)
    }

    func pauseAudio(from url: URL) {
        guard let playerNode = playerNodes[url] else { return }
        playerNode.pause()
        playingAudioSources.remove(url)
    }

    func resumeAudio(from url: URL) {
        guard let playerNode = playerNodes[url] else { return }
        playerNode.play()
        playingAudioSources.insert(url)
    }

    public func pauseAllAudio() {
        for url in playingAudioSources {
            if let playerNode = playerNodes[url] {
                playerNode.pause()
            }
        }
    }

    public func resumeAllAudio() {
        for url in playingAudioSources {
            if let playerNode = playerNodes[url] {
                playerNode.play()
            }
        }
    }

    func stopAllAudio() {
        for playerNode in playerNodes.values {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        playerNodes.removeAll()
    }

//    func startRecording() {}

    func stopRecording() {
        audioEngine.stop()
        for playerNode in playerNodes.values {
            playerNode.stop()
        }
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            LoggerHelper.shared.error("Failed to create AVAudioConverter")
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
            LoggerHelper.shared.error("Error converting buffer: \(error)")
            return nil
        }

        return convertedBuffer
    }
}
