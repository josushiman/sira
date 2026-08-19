import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Renders `App Icon.dc.html` (Claude Design project ea5a7a7f) to a 1024pt PNG.
// Geometry is the prototype's 512px art board, scaled by k. Corners are left
// square — iOS applies its own mask.
//
//   swift tools/RenderAppIcon.swift sira/Resources/Fonts/IBMPlexMono-SemiBold.ttf \
//       sira/Assets.xcassets/AppIcon.appiconset/AppIcon-light.png light
//
// Variants: light | dark | tinted.

struct Palette {
    let bg0: UInt32, bg1: UInt32
    let card: UInt32, pip: UInt32, tile: UInt32, tileInk: UInt32, dot: UInt32
    let vignette: CGFloat
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let fontURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outURL = URL(fileURLWithPath: CommandLine.arguments[2])
let variant = CommandLine.arguments[3]
let size = CGFloat(1024)
let k = size / 512

let palettes: [String: Palette] = [
    // THEMES.felt from the prototype.
    "light": Palette(bg0: 0x1B5540, bg1: 0x0F3427, card: 0xFBF8F0, pip: 0xC2452F,
                     tile: 0xEFE4C9, tileInk: 0x123A2C, dot: 0xC2452F, vignette: 0.14),
    // Felt pushed to its darker end for the dark-appearance slot.
    "dark": Palette(bg0: 0x123A2C, bg1: 0x071E16, card: 0xF1EEE2, pip: 0xB4402C,
                    tile: 0xE4D8BC, tileInk: 0x0B2A20, dot: 0xB4402C, vignette: 0.10),
    // Grayscale source for the system's tinted rendering.
    "tinted": Palette(bg0: 0x26262A, bg1: 0x0E0E10, card: 0xEDEDED, pip: 0x8A8A8A,
                      tile: 0xD2D2D2, tileInk: 0x2A2A2A, dot: 0x8A8A8A, vignette: 0.12),
]
let p = palettes[variant]!

let space = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                    bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Flip to CSS coordinates: origin top-left, y down.
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

// --- background: linear-gradient(155deg, bg0, bg1) ---
let angle = 155.0 * .pi / 180
let dir = CGPoint(x: sin(angle), y: -cos(angle))          // CSS: 0deg points up
let lineLen = abs(size * dir.x) + abs(size * dir.y)
let mid = CGPoint(x: size / 2, y: size / 2)
let start = CGPoint(x: mid.x - dir.x * lineLen / 2, y: mid.y + dir.y * lineLen / 2)
let end = CGPoint(x: mid.x + dir.x * lineLen / 2, y: mid.y - dir.y * lineLen / 2)
let bgGradient = CGGradient(colorsSpace: space,
                            colors: [rgb(p.bg0), rgb(p.bg1)] as CFArray,
                            locations: [0, 1])!
ctx.drawLinearGradient(bgGradient, start: start, end: end, options: [])

// --- vignette: radial-gradient(120% 90% at 26% 12%, white/a, transparent 62%) ---
ctx.saveGState()
let vCenter = CGPoint(x: size * 0.26, y: size * 0.12)
let rx = size * 1.20, ry = size * 0.90
ctx.translateBy(x: vCenter.x, y: vCenter.y)
ctx.scaleBy(x: 1, y: ry / rx)
let vGradient = CGGradient(colorsSpace: space,
                           colors: [rgb(0xFFFFFF, p.vignette), rgb(0xFFFFFF, 0)] as CFArray,
                           locations: [0, 0.62])!
ctx.drawRadialGradient(vGradient, startCenter: .zero, startRadius: 0,
                       endCenter: .zero, endRadius: rx, options: [.drawsAfterEndLocation])
ctx.restoreGState()

// --- art group: 300x300 centered ---
let groupX = (512 - 300) / 2 * k, groupY = (512 - 300) / 2 * k

func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h),
           cornerWidth: r, cornerHeight: r, transform: nil)
}

/// Draws `body` in a frame rotated by `deg` about its own centre, with a CSS drop shadow.
func rotated(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, deg: CGFloat,
             shadowY: CGFloat, blur: CGFloat, shadowAlpha: CGFloat,
             _ body: (CGSize) -> Void) {
    ctx.saveGState()
    ctx.translateBy(x: groupX + (x + w / 2) * k, y: groupY + (y + h / 2) * k)
    ctx.rotate(by: deg * .pi / 180)
    ctx.setShadow(offset: CGSize(width: 0, height: shadowY * k), blur: blur * k,
                  color: rgb(0x000000, shadowAlpha))
    ctx.translateBy(x: -w * k / 2, y: -h * k / 2)
    body(CGSize(width: w * k, height: h * k))
    ctx.restoreGState()
}

// Card: 132x190 @ (22,44), r20, rotate -14deg, with a 56x56 pip rotated 45deg.
rotated(x: 22, y: 44, w: 132, h: 190, deg: -14, shadowY: 12, blur: 30, shadowAlpha: 0.28) { s in
    ctx.addPath(rounded(0, 0, s.width, s.height, 20 * k))
    ctx.setFillColor(rgb(p.card))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.saveGState()
    ctx.translateBy(x: s.width / 2, y: s.height / 2)
    ctx.rotate(by: 45 * .pi / 180)
    ctx.addPath(rounded(-28 * k, -28 * k, 56 * k, 56 * k, 9 * k))
    ctx.setFillColor(rgb(p.pip))
    ctx.fillPath()
    ctx.restoreGState()
}

// Tile: 132x190 @ (144,32), r18, rotate 9deg, holding "7" over a 20px dot.
let cgFont = CGFont(CGDataProvider(url: fontURL as CFURL)!)!
let numSize = 76 * k
let font = CTFontCreateWithGraphicsFont(cgFont, numSize, nil, nil)
let tracking = -0.04 * numSize

rotated(x: 144, y: 32, w: 132, h: 190, deg: 9, shadowY: 14, blur: 34, shadowAlpha: 0.30) { s in
    ctx.addPath(rounded(0, 0, s.width, s.height, 18 * k))
    ctx.setFillColor(rgb(p.tile))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Flex column: 76 line box + 16 gap + 20 dot, centred in the 190 tall tile.
    let contentH = (76 + 16 + 20) * k
    let top = (s.height - contentH) / 2

    var glyph = CGGlyph()
    var ch: UniChar = 55 // "7"
    CTFontGetGlyphsForCharacters(font, &ch, &glyph, 1)
    var advance = CGSize()
    CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
    let ascent = CTFontGetAscent(font), descent = CTFontGetDescent(font)
    let halfLeading = (numSize - (ascent + descent)) / 2
    let baseline = top + halfLeading + ascent
    // Undo the y-flip around the baseline so the glyph draws upright.
    ctx.saveGState()
    ctx.translateBy(x: (s.width - (advance.width + tracking)) / 2, y: baseline)
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(rgb(p.tileInk))
    var pos = CGPoint.zero
    CTFontDrawGlyphs(font, &glyph, &pos, 1, ctx)
    ctx.restoreGState()

    let dotY = top + (76 + 16) * k
    ctx.addEllipse(in: CGRect(x: (s.width - 20 * k) / 2, y: dotY, width: 20 * k, height: 20 * k))
    ctx.setFillColor(rgb(p.dot))
    ctx.fillPath()
}

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outURL.lastPathComponent)")
