//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import SwiftUI

public struct StreamingLoadingIndicator: View {
    @State private var isAnimating = false

    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth = size / 10

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            .frame(width: size, height: size)
            .onAppear {
                isAnimating = true
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
