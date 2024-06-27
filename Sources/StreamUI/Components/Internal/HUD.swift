//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/27/24.
//

import ConsoleKit
import Foundation

public class HUD {
    private let console: Console
    private weak var recorder: Recorder?

//    private var bar: ActivityIndicator<LoadingBar>
    
    public init() {
        self.console = Terminal()

        console.clear(.screen)
//        self.bar = console.loadingBar(title: "Recording Video")
//        bar.start()
    }
    
    public func setRecorder(recorder: Recorder) {
        self.recorder = recorder
    }
    
    public func render() -> String {
        guard let recorder = recorder else {
            let loading = "🌀 Loading"
            console.info(loading)
            return loading
        }
        let elapsedTime = recorder.controlledClock.elapsedTime
        let elapsedTimeFormatted = formatTimeInterval(elapsedTime ?? 0)
        let stateEmoji = getStateEmoji(for: recorder.state)
        let frameCount = recorder.frameTimer.frameCount
        let totalFrames = recorder.calculateTotalFrames()
        
        let frameProgress = recorder.renderSettings.captureDuration == nil ? String(frameCount) : "\(frameCount) / \(totalFrames)"
        
        let streamsInfo = recorder.renderSettings.livestreamSettings?.count ?? 0 > 0 ? "📺 LIVE" : "NOT LIVE"
        let outputInfo = recorder.renderSettings.saveVideoFile ? recorder.renderSettings.outputURL.absoluteString : "Not Saving video"
        
        let info = """
        Time Recording: \(elapsedTimeFormatted)
        Frames Captured: \(frameProgress)
        State: \(stateEmoji)
        Output URL: \(outputInfo)
        \(streamsInfo)
        """
        
        let text = "hello"
        
        console.clear(lines: 5)
        console.info(info)
        
//        updateStatusBar(with: info)
        return info
    }
    
    private func updateStatusBar(with info: String) {
//        bar?.title = info
//        bar.activity.currentProgress = Double(frameTimer.frameCount) / Double(totalFrames)
        console.info(info)
    }
    
    private func getStateEmoji(for state: Recorder.RecordingState) -> String {
        switch state {
        case .recording:
            return "🔴 Recording"
        case .paused:
            return "⏸️ Paused"
        case .finished, .idle:
            return "✅ Finished"
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let intervalInSeconds = interval / 1000 // Convert milliseconds to seconds
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: intervalInSeconds) ?? "00:00:00"
    }
}
