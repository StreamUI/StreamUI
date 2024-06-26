//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

// import AVFoundation
// import CoreImage
// import SwiftUI
//
// class MediaPlayerManager: NSObject, ObservableObject {
//    public var player: AVPlayer?
//    private var playerItem: AVPlayerItem?
//    private var videoOutput: AVPlayerItemVideoOutput?
//    private var displayLink: DisplayLink?
//    private var audioEngine: AVAudioEngine?
//    private var playerNode: AVAudioPlayerNode?
//
//    @Published var currentFrame: CGImage?
//    @Published var currentAudioLevels: [Float] = []
//
//    private var audioBufferHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
//
//    override init() {
//        super.init()
//    }
//
//    func setAudioBufferHandler(_ handler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
//        audioBufferHandler = handler
//    }
//
//    func setupPlayer(url: URL) {
//        // Create player and player item
//        playerItem = AVPlayerItem(url: url)
//        player = AVPlayer(playerItem: playerItem)
//
//        // Setup video output
//        let videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
//        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: videoSettings)
//        playerItem?.add(videoOutput!)
//
//        // Setup audio engine
//        setupAudioEngine()
//
//        // Start display link for video frame updates
//        displayLink = DisplayLink { [weak self] in
//            self?.updateVideoFrame()
//        }
//
//        // Observe player item status
//        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
//    }
//
//    private func setupAudioEngine() {
//        audioEngine = AVAudioEngine()
//        playerNode = AVAudioPlayerNode()
//        audioEngine?.attach(playerNode!)
//
//        // Connect player node to main mixer
//        audioEngine?.connect(playerNode!, to: audioEngine!.mainMixerNode, format: nil)
//
//        // Setup tap on player node to get audio buffers
//        let mainMixerFormat = audioEngine?.mainMixerNode.outputFormat(forBus: 0)
//        playerNode?.installTap(onBus: 0, bufferSize: 1024, format: mainMixerFormat) { [weak self] buffer, time in
//            self?.audioBufferHandler?(buffer, time)
//        }
//
//        // Start audio engine
//        do {
//            try audioEngine?.start()
//        } catch {
//            print("Failed to start audio engine: \(error)")
//        }
//    }
//
//    func play() {
//        player?.play()
//        playerNode?.play()
//    }
//
//    func pause() {
//        player?.pause()
//        playerNode?.pause()
//    }
//
//    private func updateVideoFrame() {
//        guard let output = videoOutput, let player = player else { return }
//
//        let itemTime = output.itemTime(forHostTime: CACurrentMediaTime())
//        guard output.hasNewPixelBuffer(forItemTime: itemTime) else { return }
//
//        guard let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else { return }
//
//        if let cgImage = pixelBuffer.toCGImage() {
//            DispatchQueue.main.async {
//                self.currentFrame = cgImage
//            }
//        }
//
//        // Capture audio levels
//        if let playerNode = playerNode {
//            let levels = playerNode.volume
//            DispatchQueue.main.async {
//                self.currentAudioLevels = [levels]
//            }
//        }
//    }
//
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == #keyPath(AVPlayerItem.status) {
//            let status: AVPlayerItem.Status
//            if let statusNumber = change?[.newKey] as? NSNumber {
//                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
//            } else {
//                status = .unknown
//            }
//
//            switch status {
//            case .readyToPlay:
//                print("PlayerItem is ready to play")
//                // Here you can start playing if needed
//                player?.play()
//            case .failed:
//                print("PlayerItem failed to load")
//            case .unknown:
//                print("PlayerItem is in unknown state")
//            @unknown default:
//                print("PlayerItem is in an unexpected state")
//            }
//        }
//    }
//
//    deinit {
//        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
//    }
// }
//
// class DisplayLink {
//    private var displayLink: CVDisplayLink?
//    private var callback: () -> Void
//
//    init(callback: @escaping () -> Void) {
//        self.callback = callback
//        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
//        CVDisplayLinkSetOutputCallback(displayLink!, { _, _, _, _, _, userInfo in
//            let `self` = Unmanaged<DisplayLink>.fromOpaque(userInfo!).takeUnretainedValue()
//            DispatchQueue.main.async {
//                self.callback()
//            }
//            return kCVReturnSuccess
//        }, Unmanaged.passUnretained(self).toOpaque())
//        CVDisplayLinkStart(displayLink!)
//    }
//
//    deinit {
//        CVDisplayLinkStop(displayLink!)
//    }
// }
//
// public struct MediaPlayerView: View {
//    @Environment(\.recorder) private var recorder
//    @StateObject private var mediaManager = MediaPlayerManager()
//
//    private var url: URL
//
//    public init(url: URL) {
//        self.url = url
//    }
//
//    // This is a placeholder. Replace with your actual parentRecorder
//    var parentRecorder: AnyObject?
//
//    public var body: some View {
//        VStack {
//            if let frame = mediaManager.currentFrame {
//                Image(decorative: frame, scale: 1.0)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//            }
//
//            Text("Audio Levels: \(mediaManager.currentAudioLevels.description)")
//
////            Button("Play") {
////                mediaManager.play()
////            }
////
////            Button("Pause") {
////                mediaManager.pause()
////            }
//        }
//        .onAppear {
////            if let url = url {
//            mediaManager.setupPlayer(url: url)
//
////            mediaManager.play()
//
//            mediaManager.setAudioBufferHandler { buffer, time in
//                print("bufffer", buffer, time)
//                let sampleRate = buffer.format.sampleRate
//
//                let framePosition = time.sampleTime
//
//                // Convert AVAudioFramePosition to CMTime
//                let seconds = Double(framePosition) / sampleRate
//                let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
//
//                recorder?.audioRecorder.addToStream(buffer, at: cmTime)
//
////                if let presentationTime = mediaManager.player?.currentTime() {
////                    print("[AudioBuffer]", presentationTime)
////                    recorder?.audioRecorder.appendAudioBuffer(buffer, at: presentationTime)
////                }
//
//                //
////                if let presentationTime = recorder?.frameTimer.getCurrentFrameTime() {
////                    print("[AudioBuffer]", presentationTime)
////                    recorder?.audioRecorder.appendAudioBuffer(buffer, at: presentationTime)
////                }
////                    appendAudioBuffer(buffer, at: time)
//            }
////            }
//        }
//    }
// }
//
// extension CVPixelBuffer {
//    func toCGImage() -> CGImage? {
//        let ciImage = CIImage(cvPixelBuffer: self)
//        let context = CIContext(options: nil)
//        return context.createCGImage(ciImage, from: ciImage.extent)
//    }
// }
