//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import StreamUI
import SwiftUI

public struct ImageTestView: View {
    @Environment(\.recorder) private var recorder

    @State private var currentImageIndex = 0

    let imageUrls = [
        "https://sample-videos.com/img/Sample-jpg-image-5mb.jpg",
        "https://mogged-pullzone.b-cdn.net/people/8336bde2-3d36-41c3-a8ad-9c9d5413eff6.jpg?class=mobile",
        "https://mogged-pullzone.b-cdn.net/people/0880cf5d-10d1-49b2-b468-e84d19f5bdca.jpg",
        "https://mogged-pullzone.b-cdn.net/people/08c08ae7-732e-4966-917f-f94174daa024.jpg",
        "https://mogged-pullzone.b-cdn.net/people/0a4f6fc6-bc77-4b4a-9dfb-c690b5931625.jpg"
    ]

    public init() {}
    public var body: some View {
        VStack {
            StreamingImage(url: URL(string: imageUrls[currentImageIndex])!, scaleType: .fill)
                .frame(width: 1080, height: 1920)
                .id(currentImageIndex)
        }
        .onAppear(perform: startTimer)
    }

    private func startTimer() {
        Task {
            while true {
                try await recorder?.controlledClock.clock.sleep(for: .milliseconds(1000))
                currentImageIndex = (currentImageIndex + 1) % imageUrls.count
            }
        }
    }
}
