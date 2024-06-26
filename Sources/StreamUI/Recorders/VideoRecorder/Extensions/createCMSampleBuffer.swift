//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import AVFoundation
import CoreImage
import CoreVideo
import HaishinKit
import Metal
import SwiftUI
import VideoToolbox

extension VideoRecorder {
    func createCMSampleBuffer(from pixelBuffer: CVPixelBuffer, presentationTime: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var formatDesc: CMVideoFormatDescription?
        let frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(renderSettings.fps))
        var sampleTimingInfo = CMSampleTimingInfo(duration: frameDuration, // Assuming 30 fps
                                                  presentationTimeStamp: presentationTime,
                                                  decodeTimeStamp: CMTime.invalid)
        
        // Create a CMVideoFormatDescription from the pixel buffer
        let status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                  imageBuffer: pixelBuffer,
                                                                  formatDescriptionOut: &formatDesc)
        guard status == noErr, let formatDesc = formatDesc else {
            print("Failed to create CMVideoFormatDescription")
            return nil
        }
        
        //        print("Format description: \(formatDesc)")
        
        // Create the CMSampleBuffer
        let status2 = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                               imageBuffer: pixelBuffer,
                                                               formatDescription: formatDesc,
                                                               sampleTiming: &sampleTimingInfo,
                                                               sampleBufferOut: &sampleBuffer)
        guard status2 == noErr, let sampleBuffer = sampleBuffer else {
            print("Failed to create CMSampleBuffer")
            return nil
        }
        
        return sampleBuffer
    }
}
