//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import Foundation

// MARK: - ProgressBarDisplayer

public protocol ProgressBarPrinter {
    mutating func display(_ progressBar: ProgressBar)
}

struct ProgressBarTerminalPrinter: ProgressBarPrinter {
    var lastPrintedTime = 0.0

    init() {
        // the cursor is moved up before printing the progress bar.
        // have to move the cursor down one line initially.
        print("")
    }
    
    mutating func display(_ progressBar: ProgressBar) {
        let currentTime = getTimeOfDay()
        if currentTime - lastPrintedTime > 0.1 || progressBar.index == progressBar.count {
            print("\u{1B}[1A\u{1B}[K\(progressBar.value)")
            lastPrintedTime = currentTime
        }
    }
}

// MARK: - ProgressBar

public struct ProgressBar {
    public private(set) var index = 0
    public let startTime = getTimeOfDay()
    public let count: Int
    let configuration: [ProgressElementType]?
    var printer: ProgressBarPrinter
    
    public var value: String {
        let configuration = self.configuration ?? ProgressBar.defaultConfiguration
        let values = configuration.map { $0.value(self) }
        return values.joined(separator: " ")
    }
    
    public static var defaultConfiguration: [ProgressElementType] = [ProgressIndex(), ProgressBarLine(), ProgressTimeEstimates()]

    public init(count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.count = count
        self.configuration = configuration
        self.printer = printer ?? ProgressBarTerminalPrinter()
    }
    
    public mutating func next() {
        guard index <= count else { return }
        printer.display(self)
        index += 1
    }

    public mutating func setValue(_ index: Int) {
        guard index <= count, index >= 0 else { return }
        self.index = index
        printer.display(self)
    }
}

// MARK: - GeneratorType

public struct ProgressGenerator<G: IteratorProtocol>: IteratorProtocol {
    var source: G
    var progressBar: ProgressBar
    
    init(source: G, count: Int, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.source = source
        self.progressBar = ProgressBar(count: count, configuration: configuration, printer: printer)
    }
    
    public mutating func next() -> G.Element? {
        progressBar.next()
        return source.next()
    }
}

// MARK: - SequenceType

public struct Progress<G: Sequence>: Sequence {
    let generator: G
    let configuration: [ProgressElementType]?
    let printer: ProgressBarPrinter?
    
    public init(_ generator: G, configuration: [ProgressElementType]? = nil, printer: ProgressBarPrinter? = nil) {
        self.generator = generator
        self.configuration = configuration
        self.printer = printer
    }
    
    public func makeIterator() -> ProgressGenerator<G.Iterator> {
        let count = generator.underestimatedCount
        return ProgressGenerator(source: generator.makeIterator(), count: count, configuration: configuration, printer: printer)
    }
}

public protocol ProgressElementType {
    func value(_ progressBar: ProgressBar) -> String
}

// MARK: - Progress Elements

public struct ProgressBarLine: ProgressElementType {
    let barLength: Int
    
    public init(barLength: Int = 30) {
        self.barLength = barLength
    }
    
    public func value(_ progressBar: ProgressBar) -> String {
        var completedBarElements = 0
        if progressBar.count == 0 {
            completedBarElements = barLength
        } else {
            completedBarElements = Int(Double(barLength) * (Double(progressBar.index) / Double(progressBar.count)))
        }
        
        var barArray = [String](repeating: "-", count: completedBarElements)
        barArray += [String](repeating: " ", count: barLength - completedBarElements)
        return "[" + barArray.joined(separator: "") + "]"
    }
}

public struct ProgressIndex: ProgressElementType {
    public init() {}
    
    public func value(_ progressBar: ProgressBar) -> String {
        return "\(progressBar.index) of \(progressBar.count)"
    }
}

public struct ProgressPercent: ProgressElementType {
    let decimalPlaces: Int
    
    public init(decimalPlaces: Int = 0) {
        self.decimalPlaces = decimalPlaces
    }
    
    public func value(_ progressBar: ProgressBar) -> String {
        var percentDone = 100.0
        if progressBar.count > 0 {
            percentDone = Double(progressBar.index) / Double(progressBar.count) * 100
        }
        return "\(percentDone.format(decimalPlaces))%"
    }
}

public struct ProgressTimeEstimates: ProgressElementType {
    public init() {}
    
    public func value(_ progressBar: ProgressBar) -> String {
        let totalTime = getTimeOfDay() - progressBar.startTime
        
        var itemsPerSecond = 0.0
        var estimatedTimeRemaining = 0.0
        if progressBar.index > 0 {
            itemsPerSecond = Double(progressBar.index) / totalTime
            estimatedTimeRemaining = Double(progressBar.count - progressBar.index) / itemsPerSecond
        }
        
        let estimatedTimeRemainingString = formatDuration(estimatedTimeRemaining)
        
        return "ETA: \(estimatedTimeRemainingString) (at \(itemsPerSecond.format(2))) it/s)"
    }
    
    fileprivate func formatDuration(_ duration: Double) -> String {
        print("duration", duration)
        let duration = Int(duration)
        let seconds = Double(duration % 60)
        let minutes = Double((duration / 60) % 60)
        let hours = Double(duration / 3600)
        return "\(hours.format(0, minimumIntegerPartLength: 2)):\(minutes.format(0, minimumIntegerPartLength: 2)):\(seconds.format(0, minimumIntegerPartLength: 2))"
    }
}

public struct ProgressString: ProgressElementType {
    let string: String
    
    public init(string: String) {
        self.string = string
    }
    
    public func value(_: ProgressBar) -> String {
        return string
    }
}

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

func getTimeOfDay() -> Double {
    var tv = timeval()
    gettimeofday(&tv, nil)
    return Double(tv.tv_sec) + Double(tv.tv_usec) / 1000000
}

extension Double {
    func format(_ decimalPartLength: Int, minimumIntegerPartLength: Int = 0) -> String {
        let value = String(self)
        let components = value
            .split { $0 == "." }
            .map { String($0) }
        
        var integerPart = components.first ?? "0"
        
        let missingLeadingZeros = minimumIntegerPartLength - integerPart.count
        if missingLeadingZeros > 0 {
            integerPart = stringWithZeros(missingLeadingZeros) + integerPart
        }
        
        if decimalPartLength == 0 {
            return integerPart
        }
        
        var decimalPlaces = components.last?.substringWithRange(0, end: decimalPartLength) ?? "0"
        let missingPlaceCount = decimalPartLength - decimalPlaces.count
        decimalPlaces += stringWithZeros(missingPlaceCount)
        
        return "\(integerPart).\(decimalPlaces)"
    }
    
    fileprivate func stringWithZeros(_ count: Int) -> String {
        return Array(repeating: "0", count: count).joined(separator: "")
    }
}

extension String {
    func substringWithRange(_ start: Int, end: Int) -> String {
        var end = end
        if start < 0 || start > count {
            return ""
        } else if end < 0 || end > count {
            end = count
        }
        let range = index(startIndex, offsetBy: start) ..< index(startIndex, offsetBy: end)
        return String(self[range])
    }
}
