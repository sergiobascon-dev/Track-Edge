import AppKit
import Foundation
let target=CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath:target,withIntermediateDirectories:true)
func drawIcon() {
 NSColor(calibratedRed:0.96,green:0.97,blue:0.98,alpha:1).setFill()
 let tile=NSBezierPath(roundedRect:NSRect(x:72,y:72,width:880,height:880),xRadius:196,yRadius:196)
 tile.fill()
 NSColor(calibratedWhite:0.82,alpha:1).setStroke(); tile.lineWidth=8; tile.stroke()
 for (x,color) in [(296.0,NSColor(calibratedRed:1,green:0.60,blue:0.06,alpha:1)),(656.0,NSColor(calibratedRed:0.19,green:0.78,blue:0.36,alpha:1))] {
  color.setFill()
  NSBezierPath(roundedRect:NSRect(x:x,y:272,width:72,height:480),xRadius:36,yRadius:36).fill()
 }
}
for (name,pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
 let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState()
 NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
 let transform=AffineTransform(scale:CGFloat(pixels)/1024)
 (transform as NSAffineTransform).concat()
 drawIcon()
 NSGraphicsContext.restoreGraphicsState()
 try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:target).appendingPathComponent(name+".png"))
}
