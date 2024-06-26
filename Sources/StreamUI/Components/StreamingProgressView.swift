//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/25/24.
//

import SwiftUI

public struct StreamingProgressView: View {
    @Binding public var progress: Double // Progress value between 0 and 1

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
            }
        }
        .frame(height: 8)
    }
}
