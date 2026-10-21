// PNG encoding for the graph export.
//
// ponytail: ImageIO rather than UIImage.pngData()/NSBitmapImageRep — those exist on one
// platform each, and this is the only encoding step, so reaching for CoreGraphics avoids a
// #if with two implementations to keep in step.
//
// Split into its own file so Checks/main.swift can compile and actually exercise it. The
// export path is the one thing that changed when ShareSheet was removed, and a green build
// says nothing about whether real PNG bytes come out the other end.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Encodes a CGImage as PNG. Returns nil if the destination cannot be created or finalized,
/// which is the caller's cue to leave the share sheet closed rather than share nothing.
func pngData(from image: CGImage) -> Data? {
    let buffer = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        buffer, UTType.png.identifier as CFString, 1, nil
    ) else { return nil }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return buffer as Data
}
