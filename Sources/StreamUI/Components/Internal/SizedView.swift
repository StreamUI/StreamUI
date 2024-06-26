//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/14/24.
//

import Foundation
import SwiftUI

// Wrapper view to set the frame size
public struct SizedView<Content: View>: View {
    public let content: Content
    public let width: CGFloat
    public let height: CGFloat

    public init(content: Content, width: CGFloat, height: CGFloat) {
        self.content = content
        self.width = width
        self.height = height
    }

    public var body: some View {
        content
            .frame(width: width, height: height)
            .background(.white)
    }
}
