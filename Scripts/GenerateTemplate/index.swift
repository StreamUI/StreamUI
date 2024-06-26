import ArgumentParser
import Foundation
import Logging
import PathKit
import Stencil

let logger = Logger(label: "live.stream.ui.generateTemplate")

@main
struct GenerateTemplate: ParsableCommand {
    @Argument var productName: String

    mutating func run() throws {
        let currentPath = FileManager.default.currentDirectoryPath

        let templatesPath = currentPath + "/Scripts/GenerateTemplate/Templates"

        guard !FileManager.default.fileExists(atPath: productName) else {
            logger.error("\(productName) exists.")
            return
        }
        try FileManager.default.createDirectory(atPath: productName + "/Sources/", withIntermediateDirectories: true)

        try copyTemplateFile(templateName: "main.swift", fileName: "Sources/main.swift")
        try copyTemplateFile(templateName: "Package.swift", fileName: "Package.swift")

        logger.info("Creating \(productName) has been succeeded.")
    }

    private func copyTemplateFile(templateName: String, fileName: String) throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let templatePath = currentPath + "/Scripts/GenerateTemplate/Templates/" + templateName + ".stencil"

        let templateContent = try String(contentsOfFile: templatePath)
        let renderedContent = templateContent.replacingOccurrences(of: "{{ productName }}", with: productName)

        let outputPath = currentPath + "/\(productName)/" + fileName
        try renderedContent.write(toFile: outputPath, atomically: true, encoding: .utf8)

        logger.debug("Written to \(outputPath)")
    }
}
