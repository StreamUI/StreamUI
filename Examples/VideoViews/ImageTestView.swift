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

    let url = "https://sample-videos.com/img/Sample-jpg-image-5mb.jpg"

    public init() {}
    public var body: some View {
        StreamingImage(url: URL(string: url)!)
            .frame(width: 500, height: 900)

//        VideoPlayer(player: AVPlayer(url: URL(string: "https://file-examples.com/storage/fed5266c9966708dcaeaea6/2017/04/file_example_MP4_480_1_5MG.mp4")!))
//            .frame(height: 400)
    }
}
