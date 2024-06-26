//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import AVFoundation
import Foundation
import SpriteKit
import SwiftUI

public struct SpriteKitTestView: View {
    @Environment(\.recorder) private var recorder

    @State private var counter: Int = 0
    @State private var timer: Timer?
    @State private var circleSize: CGFloat = 100
    @State private var circleColor: Color = .red

    public init() {}

    public var body: some View {
        VStack {
            Text("Counter: \(counter)")
                .font(.largeTitle)
                .foregroundColor(.green)
                .padding()
                .scaleEffect(scaleEffectBasedOnFrameCount())
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scaleEffectBasedOnFrameCount())

            if let frameCount = recorder?.frameTimer.frameCount {
                Text("Current Frame -> \(frameCount)")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding()
            } else {
                Text("No frame count")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding()
            }

            Circle()
                .fill(circleColor)
                .frame(width: circleSize, height: circleSize)
                .onAppear {
                    startCircleAnimation()
                }
                .onChange(of: recorder?.frameTimer.frameCount) { _ in
                    updateCircleAnimation()
                }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            counter += 1
        }
    }

    private func scaleEffectBasedOnFrameCount() -> CGFloat {
        if let frameCount = recorder?.frameTimer.frameCount {
            return 1.0 + 0.5 * sin(Double(frameCount) / 10.0)
        }
        return 1.0
    }

    private func startCircleAnimation() {
        withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            circleSize = 150
            circleColor = .blue
        }
    }

    private func updateCircleAnimation() {
        if let frameCount = recorder?.frameTimer.frameCount {
            withAnimation(.linear(duration: 0.5)) {
                circleSize = 100 + CGFloat(frameCount % 50)
                circleColor = frameCount % 2 == 0 ? .red : .blue
            }
        }
    }
}
