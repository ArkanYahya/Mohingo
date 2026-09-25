// Renders the iOS launch image: the app icon with iOS-style rounded corners,
// at 1x, 2x and 3x of the given size in points. See docs/DESIGN_SYSTEM.md,
// Launch screen. macOS only (AppKit); run from the repository root:
//
//   swift tool/ios_launch_image.swift assets/icon/app_icon.png 120 \
//     ios/Runner/Assets.xcassets/LaunchImage.imageset
import AppKit

let args = CommandLine.arguments
let src = NSImage(contentsOfFile: args[1])!
let points = Double(args[2])!
let outDir = args[3]
for (scale, suffix) in [(1.0, ""), (2.0, "@2x"), (3.0, "@3x")] {
    let px = Int(points * scale)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.imageInterpolation = .high
    let rect = NSRect(x: 0, y: 0, width: px, height: px)
    let radius = Double(px) * 0.2237
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    src.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/LaunchImage\(suffix).png"))
    print("LaunchImage\(suffix).png \(px)x\(px)")
}
