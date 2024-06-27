//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/27/24.
//

import Logging

// Singleton Logger Helper Class
class LoggerHelper {
    // Shared instance
    static let shared = LoggerHelper()

    // Private logger instance
    private var logger: Logger

    // Private initializer to prevent external instantiation
    private init() {
        self.logger = Logger(label: "live.stream.ui")
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
    }

    // Method to log a trace message
    func trace(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .trace, message: message, metadata: metadata)
    }

    // Method to log a debug message
    func debug(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .debug, message: message, metadata: metadata)
    }

    // Method to log an info message
    func info(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .info, message: message, metadata: metadata)
    }

    // Method to log a notice message
    func notice(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .notice, message: message, metadata: metadata)
    }

    // Method to log a warning message
    func warning(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .warning, message: message, metadata: metadata)
    }

    // Method to log an error message
    func error(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .error, message: message, metadata: metadata)
    }

    // Method to log a critical message
    func critical(_ message: String, metadata: Logger.Metadata? = nil) {
        log(level: .critical, message: message, metadata: metadata)
    }

    // Method to log a message at a specific level with optional metadata
    private func log(level: Logger.Level, message: String, metadata: Logger.Metadata?) {
        if let metadata = metadata {
            logger.log(level: level, "\(message)", metadata: metadata)
        } else {
            logger.log(level: level, "\(message)")
        }
    }

    // Method to set metadata
    func setMetadata(key: String, value: String) {
        logger[metadataKey: key] = .string(value)
    }

    // Method to remove metadata
    func removeMetadata(key: String) {
        logger[metadataKey: key] = nil
    }
}
