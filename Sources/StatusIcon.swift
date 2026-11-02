import AppKit

enum StatusIcon {
 static func make() -> NSImage {
  let image=NSImage(size:NSSize(width:18,height:18),flipped:false) { _ in
   NSColor.black.setStroke()
   let outline=NSBezierPath(roundedRect:NSRect(x:1.5,y:2.5,width:15,height:13),xRadius:3,yRadius:3)
   outline.lineWidth=1; outline.stroke()
   NSColor.black.setFill()
   for x in [5.0,11.0] {
    NSBezierPath(roundedRect:NSRect(x:x,y:5,width:2,height:8),xRadius:1,yRadius:1).fill()
   }
   return true
  }
  image.isTemplate=true
  image.accessibilityDescription="TrackEdge: controles de los dos bordes del trackpad"
  return image
 }
}
