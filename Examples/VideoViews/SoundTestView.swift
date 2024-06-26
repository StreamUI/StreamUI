//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import AVFoundation
import StreamUI
import SwiftUI

public struct SoundTestView: View {
    @Environment(\.recorder) private var recorder

    let shortAudioURL = URL(string: "http://commondatastorage.googleapis.com/codeskulptor-assets/week7-brrring.m4a")!
    let bonusAudioURL = URL(string: "http://commondatastorage.googleapis.com/codeskulptor-assets/week7-bounce.m4a")!

    public init() {}

    public var body: some View {
        VStack {
            Text("playing music")
        }
        .onAppear {
            startTimer()
//            setupAudioPlayer()

            Task {
                print("going to load")
                try await recorder?.loadAudio(from: shortAudioURL)
                try await recorder?.loadAudio(from: bonusAudioURL)
                print("loaded audio")

                recorder?.playAudio(from: shortAudioURL)

                try await recorder?.controlledClock.clock.sleep(for: .seconds(3.0))
                recorder?.playAudio(from: bonusAudioURL)
                try await recorder?.controlledClock.clock.sleep(for: .seconds(1.0))

                recorder?.playAudio(from: shortAudioURL)

//                recorder?.playAudio()
            }
        }
        .onDisappear {
            print("[DEBUG] Stop Timer")
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
//            while true {
//                print("TIMER LOOP")
            ////                try await recorder?.controlledClock.clock.sleep(for: .seconds(10.0))
//                print("TIMER LOOP AFETER")
//                recorder?.playAudio(from: shortAudioURL)
//                //                try await recorder?.clock.sleep(for: .seconds(1.0 / Double(30)))
//            }
        }
    }
}
