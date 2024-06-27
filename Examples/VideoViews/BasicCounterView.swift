import AVFoundation
import StreamUI
import SwiftUI

public struct BasicCounterView: View {
    @Environment(\.recorder) private var recorder

    @State private var counter: Int
    @State private var timer: Timer?

    @State private var paused: Bool = false

    let audioUrl = URL(string: "https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.m4a")!

    private var timerTask: Task<Void, Never>?

    public init(initialCounter: Int = 10) {
        _counter = State(initialValue: initialCounter)
//        remoteAudioUrl = URL(string: "https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.m4a")!
    }

    public var body: some View {
        VStack {
            Text("Counter: \(counter)")
                .font(.largeTitle)
                .foregroundColor(.green)
                .padding()

            Text("Counter: \(recorder?.controlledClock.elapsedTime)")
                .font(.largeTitle)
                .foregroundColor(.green)
                .padding()

            if let frameCount = recorder?.frameTimer.frameCount {
                Text("Current Frame -> \(frameCount)")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("No frame count")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .foregroundColor(.green)
                    .padding()
            }
        }
//        .onChange(of: recorder?.frameCount) { _ in
        ////            print("new frame count", newCount)
//        }
        .onAppear {
            startTimer()
//            setupAudioPlayer()

            Task {
                print("going to load")
//                try await recorder?.loadAudio(from: audioUrl)
                print("loaded audio")

//                recorder?.playAudio(from: audioUrl)
            }
//            recorder.l
//            playAudio()
        }
        .onDisappear {
            print("[DEBUG] Stop Timer")
            stopTimer()
        }
//        .onChange(of: counter) { newCounter in
//            print("New counter", newCounter)
//            if newCounter == 5 {
//                print("pausing")
//                recorder?.isPaused.toggle()
//            }
//
//            if newCounter == 10 {
//                print("resuming")
//                recorder?.isPaused.toggle()
//            }
//        }
    }

    private func startTimer() {
        Task {
            while true {
                //                print("RECORDER COUNT", recorder?.frameCount)
                try await recorder?.controlledClock.clock.sleep(for: .seconds(1.0))
                //                try await recorder?.clock.sleep(for: .seconds(1.0 / Double(30)))
                counter += 1
            }
        }

//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//            counter += 1
//        }
    }

    private func stopTimer() {
//        timerTask?.cancel()
//        timerTask = nil
    }

    private func setupAudioPlayer() {
//        audioPlayer = AVPlayer(url: remoteAudioUrl)
    }

    private func playAudio() {
//        audioPlayer?.play()
    }
}

// #Preview {
//    BasicCounterView()
// }
