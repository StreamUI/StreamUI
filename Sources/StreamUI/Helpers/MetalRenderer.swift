

import CoreImage
import CoreVideo
import Metal

let metalDevice = MTLCreateSystemDefaultDevice()
let ciContext = CIContext(mtlDevice: metalDevice!, options: [.cacheIntermediates: false, .priorityRequestLow: true])

public func pixelBufferFromCGImage(_ image: CGImage, width: Int, height: Int) -> CVPixelBuffer? {
    let attrs: [String: Any] = [
        kCVPixelBufferMetalCompatibilityKey as String: true,
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ]

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs as CFDictionary, &pixelBuffer)
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        return nil
    }

    var ciImage = CIImage(cgImage: image)
    if image.width != width || image.height != height {
        ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: CGFloat(width) / CGFloat(image.width), y: CGFloat(height) / CGFloat(image.height)))
    }

    ciContext.render(ciImage, to: buffer)
    return buffer
}

////
////  File.swift
////
////
////  Created by Jordan Howlett on 6/19/24.
////
//
// import CoreGraphics
// import CoreImage
// import CoreVideo
// import Metal
// import MetalKit
//
//// Create the Metal device and CIContext once
// let metalDevice = MTLCreateSystemDefaultDevice()
// let ciContext = CIContext(mtlDevice: metalDevice!)
//
// public func pixelBufferFromCGImage(_ image: CGImage, width: Int, height: Int) -> CVPixelBuffer? {
//    let attrs = [
//        kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue!,
//        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//    ] as CFDictionary
//
//    var pixelBuffer: CVPixelBuffer?
//    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &pixelBuffer)
//    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//        return nil
//    }
//
//    CVPixelBufferLockBaseAddress(buffer, [])
//
//    // Transform only if needed
//    var ciImage = CIImage(cgImage: image)
//    if image.width != width || image.height != height {
//        let scale = CGAffineTransform(scaleX: CGFloat(width) / CGFloat(image.width), y: CGFloat(height) / CGFloat(image.height))
//        ciImage = ciImage.transformed(by: scale)
//    }
//
//    ciContext.render(ciImage, to: buffer)
//
//    CVPixelBufferUnlockBaseAddress(buffer, [])
//
//    return buffer
// }
