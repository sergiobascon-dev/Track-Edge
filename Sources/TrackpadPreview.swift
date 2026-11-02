import AppKit
final class TrackpadPreview: NSView {
 var volume: Double=0, brightness: Double=0, swapped=false
 var change: (Bool,Double)->Void = {_,_ in}
 override var intrinsicContentSize: NSSize { NSSize(width:320,height:110) }
 override func draw(_ dirtyRect: NSRect) {
  let pad=bounds.insetBy(dx:34,dy:3)
  NSColor.controlBackgroundColor.setFill(); NSBezierPath(roundedRect:pad,xRadius:14,yRadius:14).fill()
  NSColor.separatorColor.setStroke(); NSBezierPath(roundedRect:pad,xRadius:14,yRadius:14).stroke()
  for right in [false,true] {
   let isVolume=right != swapped
   let x=right ? pad.maxX-29 : pad.minX+9
   let bar=NSRect(x:x,y:pad.minY+9,width:20,height:pad.height-18)
   let color=isVolume ? NSColor.systemBlue : NSColor.systemOrange
   color.withAlphaComponent(0.12).setFill(); NSBezierPath(roundedRect:bar,xRadius:8,yRadius:8).fill()
   let fill=NSRect(x:bar.minX,y:bar.minY,width:bar.width,height:max(6,bar.height*CGFloat(isVolume ? volume : brightness)))
   color.withAlphaComponent(0.4).setFill(); NSBezierPath(roundedRect:fill,xRadius:8,yRadius:8).fill()
   let image=NSImage(systemSymbolName:isVolume ? "speaker.wave.2.fill" : "sun.max.fill",accessibilityDescription:nil)
   image?.draw(in:NSRect(x:x+3,y:pad.midY-7,width:14,height:14))
  }
  let attrs: [NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:11),.foregroundColor:NSColor.secondaryLabelColor]
  let text="\(Int(brightness*100))% brillo · \(Int(volume*100))% volumen" as NSString
  let size=text.size(withAttributes:attrs)
  text.draw(at:NSPoint(x:bounds.midX-size.width/2,y:bounds.midY-6),withAttributes:attrs)
 }
 override func mouseDown(with event: NSEvent) { update(event) }
 override func mouseDragged(with event: NSEvent) { update(event) }
 private func update(_ event: NSEvent) {
  let p=convert(event.locationInWindow,from:nil)
  guard p.x<80 || p.x>bounds.width-80 else { return }
  let value=min(1,max(0,(p.y-12)/(bounds.height-24)))
  change((p.x>bounds.midX) != swapped,value)
 }
}
