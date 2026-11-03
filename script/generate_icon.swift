import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = output.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
let master = NSImage(size: NSSize(width: 1024, height: 1024))
master.lockFocus()
let rect = NSRect(x: 24, y: 24, width: 976, height: 976)
let rounded = NSBezierPath(roundedRect: rect, xRadius: 214, yRadius: 214)
NSGradient(starting: NSColor(srgbRed: 0.20, green: 0.26, blue: 0.34, alpha: 1), ending: NSColor(srgbRed: 0.055, green: 0.085, blue: 0.13, alpha: 1))!.draw(in: rounded, angle: -70)
NSColor.white.withAlphaComponent(0.15).setStroke(); rounded.lineWidth = 3; rounded.stroke()
let plate = NSBezierPath(roundedRect: NSRect(x: 162, y: 199, width: 700, height: 626), xRadius: 100, yRadius: 100)
NSColor.white.withAlphaComponent(0.035).setFill(); plate.fill()
NSColor.white.withAlphaComponent(0.12).setStroke(); plate.lineWidth = 3; plate.stroke()
let symbol = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: nil)!
    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 540, weight: .ultraLight))!
let tinted = NSImage(size: NSSize(width: 620, height: 620))
tinted.lockFocus()
symbol.draw(in: NSRect(x: 0, y: 0, width: 620, height: 620))
NSColor(srgbRed: 0.65, green: 0.85, blue: 1, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 620, height: 620).fill(using: .sourceAtop)
tinted.unlockFocus()
tinted.draw(in: NSRect(x: 202, y: 202, width: 620, height: 620))
NSColor(srgbRed: 0.38, green: 0.73, blue: 0.97, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 759, y: 740, width: 22, height: 22)).fill()
master.unlockFocus()
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        master.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
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
try FileManager.default.removeItem(at: iconset)
