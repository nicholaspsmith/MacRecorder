#!/usr/bin/env swift
// Generates a simple placeholder app icon — a red record dot inside a white ring
// on a dark rounded square — and writes Resources/bundle/AppIcon.icns.
//
// Run from the repo root:  swift scripts/make-icon.swift
// Regenerate any time; replace with real artwork later by dropping a new
// AppIcon.icns into Resources/bundle/.
import AppKit
import Foundation

func render(size: CGFloat) -> Data {
    let pixels = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    let full = CGRect(x: 0, y: 0, width: size, height: size)
    ctx.clear(full)

    // Rounded-square background with a vertical charcoal gradient.
    let inset = size * 0.06
    let bg = full.insetBy(dx: inset, dy: inset)
    let radius = bg.width * 0.22
    let path = CGPath(roundedRect: bg, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let grad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.23, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 1).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(grad,
        start: CGPoint(x: bg.midX, y: bg.maxY),
        end: CGPoint(x: bg.midX, y: bg.minY), options: [])
    ctx.restoreGState()

    // White ring.
    let ringD = bg.width * 0.62
    let ringRect = CGRect(x: bg.midX - ringD / 2, y: bg.midY - ringD / 2, width: ringD, height: ringD)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.92).cgColor)
    ctx.setLineWidth(size * 0.035)
    ctx.strokeEllipse(in: ringRect)

    // Red record dot.
    let dotD = bg.width * 0.46
    let dotRect = CGRect(x: bg.midX - dotD / 2, y: bg.midY - dotD / 2, width: dotD, height: dotD)
    ctx.setFillColor(NSColor(calibratedRed: 0.95, green: 0.23, blue: 0.19, alpha: 1).cgColor)
    ctx.fillEllipse(in: dotRect)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = NSTemporaryDirectory() + "AppIcon.iconset"
try? fm.removeItem(atPath: iconset)
try fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)

// (point size, scale) → iconutil-required filename.
let variants: [(Int, Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
for (pt, scale) in variants {
    let px = pt * scale
    let name = scale == 1 ? "icon_\(pt)x\(pt).png" : "icon_\(pt)x\(pt)@2x.png"
    try render(size: CGFloat(px)).write(to: URL(fileURLWithPath: iconset + "/" + name))
}

try? fm.createDirectory(atPath: "Resources/bundle", withIntermediateDirectories: true)
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconset, "-o", "Resources/bundle/AppIcon.icns"]
try proc.run()
proc.waitUntilExit()
print(proc.terminationStatus == 0 ? "Wrote Resources/bundle/AppIcon.icns" : "iconutil failed (\(proc.terminationStatus))")
