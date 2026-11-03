import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let artworkURL = output.appendingPathComponent("AppIconArtwork.png")
guard let artwork = NSImage(contentsOf: artworkURL) else {
    throw NSError(domain: "PhotoStudio.Icon", code: 1,
                  userInfo: [NSLocalizedDescriptionKey: "Cannot read icon artwork: \(artworkURL.path)"])
}
let iconset = output.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: iconset) }
let master = NSImage(size: NSSize(width: 1024, height: 1024))
master.lockFocus()
let rect = NSRect(x: 64, y: 64, width: 896, height: 896)
let rounded = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
shadow.shadowBlurRadius = 16
shadow.shadowOffset = NSSize(width: 0, height: -7)
shadow.set()
NSColor.white.setFill(); rounded.fill()
NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.saveGraphicsState()
rounded.addClip()
NSGraphicsContext.current?.imageInterpolation = .high
artwork.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
NSColor.white.withAlphaComponent(0.55).setStroke()
rounded.lineWidth = 2; rounded.stroke()
master.unlockFocus()
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = .high
        master.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        let png = bitmap.representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
        if pixels == 1024 { try png.write(to: output.appendingPathComponent("AppIcon.png")) }
    }
}
func uint32Data(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return Data(bytes: &number, count: 4)
}
// Modern ICNS stores PNG representations in a typed, big-endian chunk container.
var chunks = Data()
for (type, filename) in [("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"),
                         ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"),
                         ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"),
                         ("ic10", "icon_512x512@2x.png"), ("ic11", "icon_16x16@2x.png"),
                         ("ic12", "icon_32x32@2x.png"), ("ic13", "icon_128x128@2x.png"),
                         ("ic14", "icon_256x256@2x.png")] {
    let png = try Data(contentsOf: iconset.appendingPathComponent(filename))
    chunks.append(Data(type.utf8)); chunks.append(uint32Data(png.count + 8)); chunks.append(png)
}
var icns = Data("icns".utf8); icns.append(uint32Data(chunks.count + 8)); icns.append(chunks)
try icns.write(to: output.appendingPathComponent("AppIcon.icns"))
