//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/19/24.
//

import SwiftUI

public struct RecorderKey: EnvironmentKey {
    public static let defaultValue: Recorder? = nil
}

public extension EnvironmentValues {
    var recorder: Recorder? {
        get { self[RecorderKey.self] }
        set { self[RecorderKey.self] = newValue }
    }
}
