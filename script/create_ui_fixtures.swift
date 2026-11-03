import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".fixtures/ui-1.2")
let manager = FileManager.default
func photo(_ name: String, portrait: Bool, tint: CGFloat) throws {
    let url = root.appendingPathComponent(name)
    try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let w = portrait ? 1200 : 1800, h = portrait ? 1800 : 1200
    let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let colors = [CGColor(red: 0.06, green: 0.12 + tint, blue: 0.22, alpha: 1), CGColor(red: 0.65, green: 0.65 - tint, blue: 0.37, alpha: 1)] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: colors, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: w, y: h), options: [])
    context.setFillColor(CGColor(red: 0.88, green: 0.72, blue: 0.43, alpha: 1))
    context.fillEllipse(in: CGRect(x: w / 2 - 140, y: h / 2 - 140, width: 280, height: 280))
    context.setStrokeColor(CGColor(gray: 1, alpha: 0.5)); context.setLineWidth(2)
    context.stroke(CGRect(x: 40, y: 40, width: w - 80, height: h - 80))
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fatalError("JPEG write failed") }
}
for n in 1...8 { try photo("IMG_\(n).JPG", portrait: n % 3 == 0, tint: CGFloat(n) * 0.035) }
try photo("旅拍2/IMG_2.JPG", portrait: false, tint: 0.1)
try photo("旅拍2/IMG_10.JPG", portrait: true, tint: 0.2)
try photo("旅拍2/第二天/IMG_1.JPG", portrait: true, tint: 0.05)
try photo("旅拍10/IMG_2.JPG", portrait: true, tint: 0.25)
try manager.createDirectory(at: root.appendingPathComponent("空目录"), withIntermediateDirectories: true)
for pair in [(".fixtures/raw/2414.arw", "IMG_1.ARW"), (".fixtures/raw/983.cr2", "IMG_1.CR2"), (".fixtures/raw/2414.arw", "旅拍2/IMG_2.ARW")] {
    let destination = root.appendingPathComponent(pair.1)
    if !manager.fileExists(atPath: destination.path) {
        // Copy fixtures: Trash tests must not touch the public originals.
        try manager.copyItem(at: URL(fileURLWithPath: pair.0), to: destination)
    }
}
print(root.path)
