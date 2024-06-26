import AVFoundation
import Combine
import SwiftUI

public struct StreamingVideoPlayer: View {
    @Environment(\.recorder) private var recorder
    @State private var videoFrameCaptureManager: VideoFrameCaptureManager?
    private var url: URL

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        Group {
            if let frame = videoFrameCaptureManager?.frame {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            recorder?.pauseRecording()
            videoFrameCaptureManager = VideoFrameCaptureManager(url: url)
            setupCallbacks()
        }
    }

    private func setupCallbacks() {
        videoFrameCaptureManager?.videoLoaded
            .sink {
                print("Video has loaded")
                recorder?.resumeRecording()
            }
            .store(in: &videoFrameCaptureManager!.cancellables)

        videoFrameCaptureManager?.videoLoading
            .sink {
                print("Video is loading")
            }
            .store(in: &videoFrameCaptureManager!.cancellables)
    }
}

@Observable
class VideoFrameCaptureManager {
    var frame: CGImage?
    var videoLoaded = PassthroughSubject<Void, Never>()
    var videoLoading = PassthroughSubject<Void, Never>()

    private var player: AVPlayer
    private var videoOutput: AVPlayerItemVideoOutput
    public var cancellables: Set<AnyCancellable> = []
    private var fps: Double

    init(url: URL) {
        self.fps = 30.0 // Default FPS
        self.player = AVPlayer(url: url)

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)

        if let currentItem = player.currentItem {
            currentItem.add(videoOutput)
            addObservers(to: currentItem)
        }

        player.isMuted = true // Disable audio

        player.play()
        addPeriodicTimeObserver()
    }

    private func addObservers(to item: AVPlayerItem) {
        item.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.videoLoaded.send()
                case .unknown, .failed:
                    self?.videoLoading.send()
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func addPeriodicTimeObserver() {
        let timeInterval = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            self?.captureCurrentFrame(at: time)
        }
    }

    private func captureCurrentFrame(at time: CMTime) {
        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.frame = cgImage
            }
        }
    }
}

// import AudioToolbox
// import AVFoundation
// import AVKit
// import Combine
// import Foundation
// import SwiftUI
//
// public struct StreamingVideoPlayer: View {
//    @State private var videoFrameCaptureManager: VideoFrameCaptureManager?
//    @Environment(\.recorder) private var recorder
//    @StateObject private var videoPreloader = VideoPreloader()
//    private var url: URL
//
//    public init(url: URL) {
//        self.url = url
//    }
//
//    public var body: some View {
//        Group {
//            if let frame = videoFrameCaptureManager?.frame {
//                Image(decorative: frame, scale: 1.0, orientation: .up)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                Text("Loading...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .onAppear {
//            print("preloading")
//            videoPreloader.preloadVideo(url: url)
//        }
//        .onChange(of: videoPreloader.localURL) { localURL in
//            if let localURL = localURL, let recorder = recorder {
//                videoFrameCaptureManager = VideoFrameCaptureManager(url: localURL, fps: Double(recorder.renderSettings.fps))
//                setupCallbacks()
//            }
//        }
//    }
//
//    private func setupCallbacks() {
//        videoFrameCaptureManager?.videoLoaded
//            .sink {
//                print("Video has loaded")
//            }
//            .store(in: &videoFrameCaptureManager!.cancellables)
//
//        videoFrameCaptureManager?.videoLoading
//            .sink {
//                print("Video is loading")
//            }
//            .store(in: &videoFrameCaptureManager!.cancellables)
//    }
// }
//
//// tsaohseuthoasu
//// aotnehu
//
// @Observable
// class VideoFrameCaptureManager {
//    var frame: CGImage?
//    var videoLoaded = PassthroughSubject<Void, Never>()
//    var videoLoading = PassthroughSubject<Void, Never>()
//
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
//    public var cancellables: Set<AnyCancellable> = []
//    private var fps: Double
//
//    init(url: URL, fps: Double) {
//        self.fps = fps
//        self.player = AVPlayer(url: url)
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//
//        if let currentItem = player.currentItem {
//            currentItem.add(videoOutput)
//            addObservers(to: currentItem)
//        }
//
//        player.isMuted = true // Disable audio
//
//        player.play()
//        addPeriodicTimeObserver()
//    }
//
//    private func addObservers(to item: AVPlayerItem) {
//        item.publisher(for: \.status)
//            .sink { [weak self] status in
//                switch status {
//                case .readyToPlay:
//                    self?.videoLoaded.send()
//                case .unknown, .failed:
//                    self?.videoLoading.send()
//                @unknown default:
//                    break
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    private func addPeriodicTimeObserver() {
//        let timeInterval = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                self.frame = cgImage
//            }
//        }
//    }
// }

//
// public struct StreamingVideoPlayer: View {
//    @State var videoFrameCaptureManager: VideoFrameCaptureManager?
//    @Environment(\.recorder) private var recorder
//    private var url: URL
//    private var onLoaded: () -> Void
//    private var onLoading: () -> Void
//
//    public init(url: URL, onLoaded: @escaping () -> Void = {}, onLoading: @escaping () -> Void = {}) {
//        self.url = url
//        self.onLoaded = onLoaded
//        self.onLoading = onLoading
//    }
//
//    public var body: some View {
//        Group {
//            if let frame = videoFrameCaptureManager?.frame {
//                Image(decorative: frame, scale: 1.0, orientation: .up)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                Text("Loading...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .onAppear {
//            if let recorder = recorder {
//                videoFrameCaptureManager = VideoFrameCaptureManager(url: url, fps: Double(recorder.renderSettings.fps))
//                setupCallbacks()
//            }
//        }
//    }
//
//    private func setupCallbacks() {
//        videoFrameCaptureManager?.videoLoaded
//            .sink {
////                self?.onLoaded()
//                print("loaded")
//            }
//            .store(in: &videoFrameCaptureManager!.cancellables)
//
//        videoFrameCaptureManager?.videoLoading
//            .sink {
////                self?.onLoading()
//                print("loading")
//            }
//            .store(in: &videoFrameCaptureManager!.cancellables)
//    }
// }

// @Observable
// class VideoFrameCaptureManager {
//    var frame: CGImage?
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
//    private var cancellables: Set<AnyCancellable> = []
//    private var fps: Double
//
//    init(url: URL, fps: Double) {
//        self.fps = fps
//        self.player = AVPlayer(url: url)
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//        player.currentItem?.add(videoOutput)
//
//        player.play()
//        addPeriodicTimeObserver()
//    }
//
//    private func addPeriodicTimeObserver() {
//        let timeInterval = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                self.frame = cgImage
//            }
//        }
//    }
// }
//
// public struct StreamingVideoPlayer: View {
//    @StateObject private var videoFrameCaptureManager: VideoFrameCaptureManager
//    @Environment(\.recorder) private var recorder
//    private var url: URL
//
//    @State var isRecording: Bool = false
//
//    public init(url: URL) {
//        self.url = url
//        _videoFrameCaptureManager = StateObject(wrappedValue: VideoFrameCaptureManager(url: url))
//    }
//
//    public var body: some View {
//        Group {
//            if let frame = videoFrameCaptureManager.frame {
//                Image(decorative: frame, scale: 1.0, orientation: .up)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .onAppear {
//                        if isRecording { return }
//                        recorder?.resumeRecording()
//                        isRecording = true
//                    }
//            } else {
//                Text("Loading...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .onAppear {
//            if let recorder = recorder {
//                recorder.pauseRecording()
//                videoFrameCaptureManager.setRecorder(recorder)
//            }
//
//            // Ensure the recorder is not nil and initialize the capture manager
//            //            if let recorder = recorder {
//            ////                videoFrameCaptureManager = VideoFrameCaptureManager(url: url, fps: Double(recorder.renderSettings.fps))
//            //                videoFrameCaptureManager = VideoFrameCaptureManager(url: url)
//            //            }
//            //        }
//        }
//    }
// }

// class VideoFrameCaptureManager: ObservableObject {
//    @Published var frame: CGImage?
//
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
////    private var audioEngine: AVAudioEngine
////    private var playerNode: AVAudioPlayerNode
//    private var audioEngine = SharedAudioManager.shared.audioEngine
//    private var playerNode = SharedAudioManager.shared.playerNode
//    private weak var recorder: Recorder?
//
//    init(url: URL) {
//        self.player = AVPlayer(url: url)
////        self.audioEngine = audioEngine
////        self.playerNode = AVAudioPlayerNode()
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//        player.currentItem?.add(videoOutput)
//
////        setupAudioT]]]]]]]][[[[ap()
//        setupAudioTap()
//        addPeriodicTimeObserver()
//    }
//
//    func setRecorder(_ recorder: Recorder) {
//        self.recorder = recorder
//    }
//
//    private func setupAudioTap() {
//        let playerItem = player.currentItem!
//        let audioMixInput = AVMutableAudioMixInputParameters(track: playerItem.asset.tracks(withMediaType: .audio)[0])
//        let audioMix = AVMutableAudioMix()
//        audioMix.inputParameters = [audioMixInput]
//        playerItem.audioMix = audioMix
//
//        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
//        audioEngine.attach(playerNode)
//        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
//
//        playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
//            print("AUDIOBUFFER????")
//            guard let self = self, let recorder = self.recorder else { return }
//            let playerTime = self.player.currentTime()
////            let presentationTime = recorder.getCurrentTime()
////            print("AUDIO: PlayerTime -> ", playerTime, " Pres time -> ", presentationTime)
////            recorder.audioRecorder.addToStream(buffer, at: presentationTime)
//
////            recorder.audioRecorder.addToStream(buffer, at: playerTime)
//        }
//
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Failed to start audio engine: \(error)")
//        }
//    }
//
//    private func addPeriodicTimeObserver() {
//        print("CAPATURE ME")
//        let timeInterval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            print("CAPATURE ME")
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        print("capt frame")
//        guard videoOutput.hasNewPixelBuffer(forItemTime: time),
//              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
//        else {
//            print("something no")
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                print("setting new frame")
//                self.frame = cgImage
//            }
//        }
//    }
//
//    func play() {
//        player.play()
//        playerNode.play()
//    }
//
//    func pause() {
//        player.pause()
//        playerNode.pause()
//    }
//
//    func stop() {
//        player.pause()
//        player.seek(to: .zero)
//        playerNode.stop()
//    }
// }
//
//// class VideoFrameCaptureManager: ObservableObject {
////    @Published var frame: CGImage?
////
////    private var player: AVPlayer
////    private var videoOutput: AVPlayerItemVideoOutput
////    private var audioEngine: AVAudioEngine
////    private var playerNode: AVAudioPlayerNode
////    private var recorder: Recorder?
////    private var cancellables: Set<AnyCancellable> = []
////
////    init(url: URL) {
////        self.player = AVPlayer(url: url)
////
////        let pixelBufferAttributes: [String: Any] = [
////            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
////        ]
////        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
////        player.currentItem?.add(videoOutput)
////
////        self.audioEngine = AVAudioEngine()
////        self.playerNode = AVAudioPlayerNode()
////        audioEngine.attach(playerNode)
////
////        setupAudioCapture()
////
////        player.play()
////        addPeriodicTimeObserver()
////    }
////
////    func setRecorder(_ recorder: Recorder) {
////        self.recorder = recorder
////    }
////
////    private func setupAudioCapture() {
////        guard let playerItem = player.currentItem else { return }
////
////        // Configure audio engine
////        let playerAudioNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
////            let audioBuffer = UnsafeMutableAudioBufferListPointer(audioBufferList)
////            for frame in 0 ..< Int(frameCount) {
////                // Fill the buffer with audio data from the player
////                // This is a placeholder and needs to be implemented
////                let value = Float(0) // Replace with actual audio sample
////                audioBuffer[0].mData?.assumingMemoryBound(to: Float.self)[frame] = value
////            }
////            return noErr
////        }
////
////        audioEngine.attach(playerAudioNode)
////        audioEngine.connect(playerAudioNode, to: audioEngine.mainMixerNode, format: nil)
////
////        // Create a tap on the main mixer node to capture audio
////        let bufferSize = AVAudioFrameCount(44100 * 5) // 5 seconds buffer at 44.1kHz
////        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
////
////        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
////            print("[AUDIOSHIT], ", buffer, time)
////            if let self = self, let recorder = self.recorder {
//////                recorder.audioRecorder.addToStream(buffer, at: time)
////                let presentationTime = recorder.getCurrentTime()
//////                recorder.audioRecorder.addToStream(buffer, at: time)
////            }
////        }
////
////        // Start the audio engine
////        do {
////            try audioEngine.start()
////        } catch {
////            print("Failed to start audio engine: \(error)")
////        }
////
////        // Observe player's timeControlStatus to start/stop audio capture
////        player.publisher(for: \.timeControlStatus)
////            .sink { [weak self] status in
////                switch status {
////                case .playing:
////                    self?.audioEngine.mainMixerNode.volume = 1.0
////                case .paused, .waitingToPlayAtSpecifiedRate:
////                    self?.audioEngine.mainMixerNode.volume = 0.0
////                @unknown default:
////                    break
////                }
////            }
////            .store(in: &cancellables)
////    }
////
////    private func addPeriodicTimeObserver() {
////        let timeInterval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
////        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
////            self?.captureCurrentFrame(at: time)
////        }
////    }
////
////    private func captureCurrentFrame(at time: CMTime) {
////        guard videoOutput.hasNewPixelBuffer(forItemTime: time),
////              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
////        else {
////            return
////        }
////
////        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
////        let context = CIContext(options: nil)
////
////        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
////            DispatchQueue.main.async {
////                self.frame = cgImage
////            }
////        }
////    }
//// }
//
// class VideoFrameCaptureManager: ObservableObject {
//    @Published var frame: CGImage?
//
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
//    private var audioEngine: AVAudioEngine
//    private var playerNode: AVAudioPlayerNode
//    private var recorder: Recorder?
//
//    private var audioBufferList = AudioBufferList()
//    private var audioFormat = AudioStreamBasicDescription()
//
//    init(url: URL) {
//        self.player = AVPlayer(url: url)
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//        player.currentItem?.add(videoOutput)
//
//        self.audioEngine = AVAudioEngine()
//        self.playerNode = AVAudioPlayerNode()
////        audioEngine.attach(playerNode)
//
////        setupAudioEngine()
//        setupAudioTap()
//
//        player.play()
//        addPeriodicTimeObserver()
//    }
//
//    func setRecorder(_ recorder: Recorder) {
//        self.recorder = recorder
//    }
//
//    private func setupAudioEngine() {
//        let mainMixer = audioEngine.mainMixerNode
//        audioEngine.connect(playerNode, to: mainMixer, format: nil)
//        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
//
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Error starting audio engine: \(error)")
//        }
//    }
//
////    private func setupAudioEngine() {
////        let mainMixer = audioEngine.mainMixerNode
////        audioEngine.connect(playerNode, to: mainMixer, format: nil)
////
////        do {
////            try audioEngine.start()
////        } catch {
////            print("Error starting audio engine: \(error)")
////        }
////    }
//
//    private func setupAudioTap() {
//        guard let playerItem = player.currentItem,
//              let assetTrack = playerItem.asset.tracks(withMediaType: .audio).first
//        else {
//            return
//        }
//
//        let inputParams = AVMutableAudioMixInputParameters(track: assetTrack)
//
//        var callbacks = MTAudioProcessingTapCallbacks(
//            version: kMTAudioProcessingTapCallbacksVersion_0,
//            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
//            init: audioTapInit,
//            finalize: audioTapFinalize,
//            prepare: audioTapPrepare,
//            unprepare: audioTapUnprepare,
//            process: audioTapProcess
//        )
//
//        var tap: Unmanaged<MTAudioProcessingTap>?
//        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
//
//        if status == noErr, let tap = tap {
//            inputParams.audioTapProcessor = tap.takeUnretainedValue()
//            let audioMix = AVMutableAudioMix()
//            audioMix.inputParameters = [inputParams]
//            playerItem.audioMix = audioMix
//        } else {
//            print("Unable to create audio processing tap: \(status)")
//        }
//    }
//
//    private func addPeriodicTimeObserver() {
//        let timeInterval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        guard videoOutput.hasNewPixelBuffer(forItemTime: time),
//              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
//        else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                self.frame = cgImage
//            }
//        }
//    }
//
//    // MTAudioProcessingTap callback functions
//    // MTAudioProcessingTap callback functions
//    private let audioTapInit: MTAudioProcessingTapInitCallback = { _, clientInfo, tapStorageOut in
//        tapStorageOut.pointee = clientInfo
//    }
//
//    private let audioTapFinalize: MTAudioProcessingTapFinalizeCallback = { _ in
//    }
//
//    private let audioTapPrepare: MTAudioProcessingTapPrepareCallback = { tap, maxFrames, processingFormat in
//        let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//        manager.audioFormat = processingFormat.pointee
//
//        let numChannels = Int(manager.audioFormat.mChannelsPerFrame)
//        let bufferSize = UInt32(maxFrames) * manager.audioFormat.mBytesPerFrame
//        manager.audioBufferList = AudioBufferList(
//            mNumberBuffers: 1,
//            mBuffers: AudioBuffer(
//                mNumberChannels: UInt32(numChannels),
//                mDataByteSize: bufferSize,
//                mData: malloc(Int(bufferSize))
//            )
//        )
//    }
//
//    private let audioTapUnprepare: MTAudioProcessingTapUnprepareCallback = { tap in
//        let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//        let bufferList = manager.audioBufferList
//        free(bufferList.mBuffers.mData)
//    }
//
//    private let audioTapProcess: MTAudioProcessingTapProcessCallback = { tap, numberFrames, _, bufferListInOut, numberFramesOut, flagsOut in
//        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
//
//        if status == noErr {
//            let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//
////            let audioBufferList = UnsafeMutableAudioBufferListPointer(bufferListInOut)
////            let format = manager.audioEngine.outputNode.outputFormat(forBus: 0)
////            let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numberFrames))!
////            audioBuffer.frameLength = AVAudioFrameCount(numberFrames)
//
////            for bufferIndex in 0 ..< audioBufferList.count {
////                let srcBuffer = audioBufferList[bufferIndex]
////                let destBuffer = audioBuffer.floatChannelData![bufferIndex]
////                memcpy(destBuffer, srcBuffer.mData, Int(srcBuffer.mDataByteSize))
////            }
//
//            let inputBufferList = bufferListInOut.pointee
//            let buffer = manager.audioBufferList.mBuffers
//            let inputBuffer = inputBufferList.mBuffers
//
//            memcpy(buffer.mData, inputBuffer.mData, Int(inputBuffer.mDataByteSize))
//
//            print("GOTEM", tap, numberFramesOut, bufferListInOut)
//
//            let format = manager.audioEngine.outputNode.outputFormat(forBus: 0)
//            let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numberFrames))!
//            audioBuffer.frameLength = AVAudioFrameCount(numberFrames)
//
//            for bufferIndex in 0 ..< manager.audioBufferList.mNumberBuffers {
//                let srcBuffer = UnsafeMutableAudioBufferListPointer(bufferListInOut)[UnsafeMutableAudioBufferListPointer.Index(bufferIndex)]
//                let destBuffer = audioBuffer.floatChannelData![Int(bufferIndex)]
//                memcpy(destBuffer, srcBuffer.mData, Int(srcBuffer.mDataByteSize))
//            }
//
//            if let presentationTime = manager.recorder?.getCurrentTime() {
//                print("[AudioBuffer]", presentationTime)
//                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
//            }
//
////            if let presentationTime = manager.player.tim {
////                print("[AudioBuffer]", presentationTime)
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////            }
//
////            if let playerItem = manager.player.currentItem {
////                let currentTime = playerItem.currentTime()
////                let presentationTime = CMTimeMake(value: Int64(currentTime.value), timescale: currentTime.timescale)
////
////                // Append the audio buffer to the recorder
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////            }
//
////            if let presentationTime = manager.recorder?.getCurrentTime() {
////                print("[AudioBuffer]", presentationTime)
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////                //                manager.recorder?.audioRecorder.appendAudioBuffer(audioBuffer, at: presentationTime)
////            }
//
////            enum BufferCounter {
////                static var count = 0
////            }
////
////            BufferCounter.count += 1
////
////            // Process only every other buffer
////            if BufferCounter.count % 2 == 0 {
////                if let presentationTime = manager.recorder?.getCurrentTime() {
////                    print("[AudioBuffer]", presentationTime)
////                    manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////                }
////            }
//
////            let presentationTime = CMTimeMake(value: Int64(numberFrames), timescale: 44100)
////            manager.recorder?.audioRecorder.appendAudioBuffer(audioBuffer)
//        } else {
//            print("Error getting source audio: \(status)")
//        }
//    }
// }

// class VideoFrameCaptureManager: ObservableObject {
//    @Published var frame: CGImage?
//
//    private var player: AVPlayer?
//    private var videoOutput: AVPlayerItemVideoOutput?
//    private var audioEngine: AVAudioEngine
//    private var playerNode: AVAudioPlayerNode
//    private var recorder: Recorder?
//    private var cancellables = Set<AnyCancellable>()
//
//    private var audioBufferList = AudioBufferList()
//    private var audioFormat = AudioStreamBasicDescription()
//
//    init(url: URL) {
//        self.audioEngine = AVAudioEngine()
//        self.playerNode = AVAudioPlayerNode()
////        setupAudioTap()
//        downloadVideo(from: url)
//    }
//
//    func setRecorder(_ recorder: Recorder) {
//        self.recorder = recorder
//    }
//
//    private func downloadVideo(from url: URL) {
//        print("downloading video")
//        URLSession.shared.dataTaskPublisher(for: url)
//            .map { $0.data }
//            .sink(receiveCompletion: { completion in
//                if case .failure(let error) = completion {
//                    print("Error downloading video: \(error)")
//                }
//            }, receiveValue: { [weak self] data in
//                self?.saveAndPlayVideo(data: data)
//            })
//            .store(in: &cancellables)
//    }
//
//    private func saveAndPlayVideo(data: Data) {
//        print("save and play")
//        let tempDirectory = FileManager.default.temporaryDirectory
//        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
//
//        do {
//            try data.write(to: tempFileURL)
//            DispatchQueue.main.async {
//                self.setupPlayer(url: tempFileURL)
//            }
//        } catch {
//            print("Error saving video: \(error)")
//        }
//    }
//
//    private func setupPlayer(url: URL) {
//        player = AVPlayer(url: url)
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//        player?.currentItem?.add(videoOutput!)
//
//        player?.play()
//        setupAudioTap()
//        addPeriodicTimeObserver()
//    }
//
//    private func setupAudioTap() {
//        // Audio tap setup code remains the same
//        guard let playerItem = player?.currentItem,
//              let assetTrack = playerItem.asset.tracks(withMediaType: .audio).first
//        else {
//            return
//        }
//
//        let inputParams = AVMutableAudioMixInputParameters(track: assetTrack)
//
//        var callbacks = MTAudioProcessingTapCallbacks(
//            version: kMTAudioProcessingTapCallbacksVersion_0,
//            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
//            init: audioTapInit,
//            finalize: audioTapFinalize,
//            prepare: audioTapPrepare,
//            unprepare: audioTapUnprepare,
//            process: audioTapProcess
//        )
//
//        var tap: Unmanaged<MTAudioProcessingTap>?
//        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
//
//        if status == noErr, let tap = tap {
//            inputParams.audioTapProcessor = tap.takeUnretainedValue()
//            let audioMix = AVMutableAudioMix()
//            audioMix.inputParameters = [inputParams]
//            playerItem.audioMix = audioMix
//        } else {
//            print("Unable to create audio processing tap: \(status)")
//        }
//    }
//
//    private func addPeriodicTimeObserver() {
//        print("setting up periodic")
//        let timeInterval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player?.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        print("capturing fraem", time)
//        guard let videoOutput = videoOutput, videoOutput.hasNewPixelBuffer(forItemTime: time),
//              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
//        else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                print("setting frame image")
//                self.frame = cgImage
//            }
//        }
//    }
//
//    // MTAudioProcessingTap callback functions
//    private let audioTapInit: MTAudioProcessingTapInitCallback = { _, clientInfo, tapStorageOut in
//        tapStorageOut.pointee = clientInfo
//    }
//
//    private let audioTapFinalize: MTAudioProcessingTapFinalizeCallback = { _ in
//    }
//
//    private let audioTapPrepare: MTAudioProcessingTapPrepareCallback = { tap, _, basicDescription in
//        let selfMediaInput = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//        selfMediaInput.audioFormat = AudioStreamBasicDescription(mSampleRate: basicDescription.pointee.mSampleRate,
//                                                                 mFormatID: basicDescription.pointee.mFormatID, mFormatFlags: basicDescription.pointee.mFormatFlags, mBytesPerPacket: basicDescription.pointee.mBytesPerPacket, mFramesPerPacket: basicDescription.pointee.mFramesPerPacket, mBytesPerFrame: basicDescription.pointee.mBytesPerFrame, mChannelsPerFrame: basicDescription.pointee.mChannelsPerFrame, mBitsPerChannel: basicDescription.pointee.mBitsPerChannel, mReserved: basicDescription.pointee.mReserved)
//
////        let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
////        manager.audioFormat = processingFormat.pointee
////
//        ////        let numChannels = Int(manager.audioFormat.mChannelsPerFrame)
//        ////        let bufferSize = UInt32(maxFrames) * manager.audioFormat.mBytesPerFrame
////        let numChannels = 2
////
////        let hz = 100.0
////        let bufferDurationSeconds = 0.1 // 100 ms
////        let bufferSize = AVAudioFrameCount(bufferDurationSeconds * hz)
////        print("BUFFERSIZE", bufferSize)
////        manager.audioBufferList = AudioBufferList(
////            mNumberBuffers: 1,
////            mBuffers: AudioBuffer(
////                mNumberChannels: UInt32(numChannels),
////                mDataByteSize: bufferSize,
////                mData: malloc(Int(bufferSize))
////            )
////        )
//    }
//
//    private let audioTapUnprepare: MTAudioProcessingTapUnprepareCallback = { tap in
//        let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//        let bufferList = manager.audioBufferList
//        free(bufferList.mBuffers.mData)
//    }
//
//    private let audioTapProcess: MTAudioProcessingTapProcessCallback = { tap, numberFrames, _, bufferListInOut, numberFramesOut, flagsOut in
//        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
//
//        if status == noErr {
//            let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//            let audioFormat = manager.audioEngine.outputNode.outputFormat(forBus: 0)
//
////            let audioFormat = manager.audioFormat
//
//            guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(numberFrames)) else {
//                print("Failed to create AVAudioPCMBuffer")
//                return
//            }
//            audioBuffer.frameLength = AVAudioFrameCount(numberFrames)
//
//            // Process each audio buffer
//            for bufferIndex in 0 ..< Int(bufferListInOut.pointee.mNumberBuffers) {
//                let srcBuffer = UnsafeMutableAudioBufferListPointer(bufferListInOut)[bufferIndex]
//                guard let srcBufferData = srcBuffer.mData else { continue }
//                if let channelData = audioBuffer.floatChannelData?[bufferIndex] {
//                    memcpy(channelData, srcBufferData, Int(srcBuffer.mDataByteSize))
//                }
//            }
//
//            if let presentationTime = manager.player?.currentTime() {
//                print("[AudioBuffer]", presentationTime)
//                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
//            }
//
////            var timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1, timescale: Int32(audioFormat.mSampleRate)), presentationTimeStamp: manager.player!.currentTime(), decodeTimeStamp: CMTime.invalid)
//
////            let format = manager.audioEngine.outputNode.outputFormat(forBus: 0)
////            let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numberFrames))!
////            audioBuffer.frameLength = AVAudioFrameCount(numberFrames)
////
////            for bufferIndex in 0 ..< Int(bufferListInOut.pointee.mNumberBuffers) {
////                let srcBuffer = UnsafeMutableAudioBufferListPointer(bufferListInOut)[bufferIndex]
////                let destBuffer = audioBuffer.floatChannelData![bufferIndex]
////                memcpy(destBuffer, srcBuffer.mData, Int(srcBuffer.mDataByteSize))
////            }
////
////            if let presentationTime = manager.recorder?.frameTimer.getCurrentFrameTime() {
////                print("[AudioBuffer]", presentationTime)
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////            }
//
////            if let presentationTime = manager.player?.currentTime() {
////                print("[AudioBuffer]", presentationTime)
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////            }
//
//        } else {
//            print("Error getting source audio: \(status)")
//        }
//    }
//
////    private let audioTapProcess: MTAudioProcessingTapProcessCallback = { tap, numberFrames, _, bufferListInOut, numberFramesOut, flagsOut in
////        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
////
////        if status == noErr {
////            let manager = Unmanaged<VideoFrameCaptureManager>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
////
////            let inputBufferList = bufferListInOut.pointee
////            let buffer = manager.audioBufferList.mBuffers
////            let inputBuffer = inputBufferList.mBuffers
////
////            memcpy(buffer.mData, inputBuffer.mData, Int(inputBuffer.mDataByteSize))
////
////            print("GOTEM", tap, numberFramesOut, bufferListInOut)
////
////            let format = manager.audioEngine.outputNode.outputFormat(forBus: 0)
////            let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numberFrames))!
////            audioBuffer.frameLength = AVAudioFrameCount(numberFrames)
////
////            for bufferIndex in 0 ..< manager.audioBufferList.mNumberBuffers {
////                let srcBuffer = UnsafeMutableAudioBufferListPointer(bufferListInOut)[UnsafeMutableAudioBufferListPointer.Index(bufferIndex)]
////                let destBuffer = audioBuffer.floatChannelData![Int(bufferIndex)]
////                memcpy(destBuffer, srcBuffer.mData, Int(srcBuffer.mDataByteSize))
////            }
////
//    ////            var timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1, timescale: Int32(format.streamDescription.mSampleRate)), presentationTimeStamp: self.player.currentTime(), decodeTimeStamp: CMTime.invalid)
////
//    ////            manager.recorder?.frameTimer.getCurrentFrameTime()
////
//    ////            if let presentationTime = manager.recorder?.getCurrentTime() {
//    ////            if let presentationTime = manager. ?.getCurrentFrameTime() {
////            if let presentationTime = manager.recorder?.frameTimer.getCurrentFrameTime() {
////                print("[AudioBuffer]", presentationTime)
////                manager.recorder?.audioRecorder.addToStream(audioBuffer, at: presentationTime)
////            }
////
////        } else {
////            print("Error getting source audio: \(status)")
////        }
////    }
// }

// @Observable
// class VideoFrameCaptureManager {
//    var frame: CGImage?
//    var videoLoaded = PassthroughSubject<Void, Never>()
//    var videoLoading = PassthroughSubject<Void, Never>()
//
//    private var player: AVPlayer
//    private var videoOutput: AVPlayerItemVideoOutput
//    public var cancellables: Set<AnyCancellable> = []
//    private var fps: Double
//
//    init(url: URL, fps: Double) {
//        self.fps = fps
//        self.player = AVPlayer(url: url)
//
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        self.videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferAttributes)
//
//        if let currentItem = player.currentItem {
//            currentItem.add(videoOutput)
//            addObservers(to: currentItem)
//        }
//
//        player.isMuted = true // Disable audio
//
//        player.play()
//        addPeriodicTimeObserver()
//    }
//
//    private func addObservers(to item: AVPlayerItem) {
//        item.publisher(for: \.status)
//            .sink { [weak self] status in
//                switch status {
//                case .readyToPlay:
//                    self?.videoLoaded.send()
//                case .unknown, .failed:
//                    self?.videoLoading.send()
//                @unknown default:
//                    break
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    private func addPeriodicTimeObserver() {
//        let timeInterval = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
//            self?.captureCurrentFrame(at: time)
//        }
//    }
//
//    private func captureCurrentFrame(at time: CMTime) {
//        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
//            return
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext(options: nil)
//
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            DispatchQueue.main.async {
//                self.frame = cgImage
//            }
//        }
//    }
// }
//
