import AppKit
import ServiceManagement
import ApplicationServices

private let accent=NSColor(calibratedRed:0.40,green:0.23,blue:0.93,alpha:1)
final class PanelButton: NSButton {
 var handler: ()->Void = {}
 init(_ title: String = "", symbol: String? = nil, handler: @escaping ()->Void) {
  super.init(frame:.zero); self.handler=handler; self.title=title
  isBordered=false; font = .systemFont(ofSize:12); target=self; action=#selector(run)
  if let symbol { image=NSImage(systemSymbolName:symbol,accessibilityDescription:title); imagePosition=title.isEmpty ? .imageOnly : .imageLeading }
 }
 required init?(coder: NSCoder) { fatalError() }
 @objc func run() { handler() }
}
final class PanelToggle: NSButton {
 var handler: (Bool)->Void = {_ in}
 init(on: Bool, title: String, handler: @escaping (Bool)->Void) {
  super.init(frame:.zero); self.handler=handler; self.title=""; state=on ? .on : .off
  setButtonType(.pushOnPushOff); isBordered=false; target=self; action=#selector(changed)
  setAccessibilityLabel(title); setAccessibilityRole(.checkBox)
 }
 required init?(coder: NSCoder) { fatalError() }
 @objc func changed() { needsDisplay=true; handler(state == .on) }
 override func draw(_ dirtyRect: NSRect) {
  let on=state == .on
  (on ? accent : NSColor.quaternaryLabelColor).setFill()
  NSBezierPath(roundedRect:NSRect(x:0,y:2,width:27,height:15),xRadius:7.5,yRadius:7.5).fill()
  NSColor.white.setFill(); NSBezierPath(ovalIn:NSRect(x:on ? 13 : 1,y:3,width:13,height:13)).fill()
 }
}
final class PanelSlider: NSSlider {
 var changed: (Double)->Void = {_ in}
 init(value: Double,min: Double,max: Double,title: String, changed: @escaping (Double)->Void) {
  super.init(frame:.zero); minValue=min; maxValue=max; doubleValue=value; self.changed=changed
  isContinuous=true; target=self; action=#selector(moved); setAccessibilityLabel(title)
 }
 required init?(coder:NSCoder) { fatalError() }
 @objc func moved() { changed(doubleValue); needsDisplay=true }
 override func draw(_ dirtyRect:NSRect) {
  let track=NSRect(x:0,y:2,width:bounds.width,height:18)
  NSColor.quaternaryLabelColor.withAlphaComponent(0.11).setFill()
  NSBezierPath(roundedRect:track,xRadius:9,yRadius:9).fill()
  let f=(doubleValue-minValue)/(maxValue-minValue)
  let x=9+CGFloat(f)*(bounds.width-18)
  accent.setFill(); NSBezierPath(roundedRect:NSRect(x:0,y:2,width:x+9,height:18),xRadius:9,yRadius:9).fill()
  for i in 0...14 {
   let dx=9+CGFloat(i)*(bounds.width-18)/14
   (dx < x ? NSColor.white.withAlphaComponent(0.20) : NSColor.labelColor.withAlphaComponent(0.17)).setFill()
   NSBezierPath(ovalIn:NSRect(x:dx-1,y:10,width:2,height:2)).fill()
  }
  NSColor.white.setFill(); NSBezierPath(ovalIn:NSRect(x:x-6,y:5,width:12,height:12)).fill()
 }
 override func mouseDown(with event:NSEvent) { setValue(event); while let e=window?.nextEvent(matching:[.leftMouseDragged,.leftMouseUp]) { if e.type == .leftMouseUp { break }; setValue(e) } }
 private func setValue(_ event:NSEvent) {
  let x=convert(event.locationInWindow,from:nil).x
  doubleValue=minValue+Double(min(1,max(0,(x-9)/(bounds.width-18))))*(maxValue-minValue)
  moved()
 }
}
final class PanelIcon: NSView {
 var symbol: String; var enabled:Bool
 init(_ symbol:String,enabled:Bool) { self.symbol=symbol; self.enabled=enabled; super.init(frame:.zero) }
 required init?(coder:NSCoder) { fatalError() }
 override func draw(_ dirtyRect:NSRect) {
  (enabled ? accent : NSColor.quaternaryLabelColor.withAlphaComponent(0.12)).setFill()
  NSBezierPath(ovalIn:bounds.insetBy(dx:1,dy:1)).fill()
  let img=NSImage(systemSymbolName:symbol,accessibilityDescription:nil)?.withSymbolConfiguration(.init(pointSize:12,weight:.medium))
  let tint=enabled ? NSColor.white : NSColor.labelColor
  let colored=NSImage(size:NSSize(width:15,height:15),flipped:false) { r in
   img?.draw(in:r); tint.setFill(); r.fill(using:.sourceAtop); return true
  }
  colored.draw(in:bounds.insetBy(dx:7,dy:7))
 }
}
final class LevelCard: NSView {
 var system:SystemControls
 var swapped=false
 var changed: ()->Void = {}
 override var isFlipped:Bool { true }
 init(system:SystemControls) { self.system=system; super.init(frame:.zero) }
 required init?(coder:NSCoder) { fatalError() }
 override func draw(_ dirtyRect:NSRect) {
  NSColor.labelColor.withAlphaComponent(0.035).setFill()
  let box=NSBezierPath(roundedRect:bounds.insetBy(dx:0.5,dy:0.5),xRadius:14,yRadius:14); box.fill()
  NSColor.separatorColor.withAlphaComponent(0.20).setStroke(); box.lineWidth=1; box.stroke()
  for right in [false,true] {
   let volume=right != swapped
   let v=volume ? system.volume ?? 0 : system.brightness ?? 0
   let color=volume ? NSColor.systemGreen : NSColor.systemOrange
   let x:CGFloat=right ? bounds.width-14 : 10
   NSColor.labelColor.withAlphaComponent(0.07).setFill()
   NSBezierPath(roundedRect:NSRect(x:x,y:12,width:4,height:bounds.height-24),xRadius:2,yRadius:2).fill()
   color.setFill()
   let h=(bounds.height-24)*CGFloat(v)
   NSBezierPath(roundedRect:NSRect(x:x,y:bounds.height-12-h,width:4,height:h),xRadius:2,yRadius:2).fill()
   let title=volume ? "VOLUME" : "BRIGHTNESS"
   let attrs:[NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:9,weight:.semibold),.foregroundColor:NSColor.labelColor,.kern:1.1]
   let tx:CGFloat=right ? bounds.width-94 : 44
   (title as NSString).draw(at:NSPoint(x:tx,y:24),withAttributes:attrs)
   let symbol=NSImage(systemSymbolName:volume ? "speaker.wave.2.fill" : "sun.max.fill",accessibilityDescription:nil)
   let iconX:CGFloat=right ? bounds.width-42 : 28
   let iconRect=NSRect(x:iconX,y:24,width:11,height:11)
   let tinted=NSImage(size:iconRect.size,flipped:false) { r in symbol?.draw(in:r); color.setFill(); r.fill(using:.sourceAtop); return true }
   tinted.draw(in:iconRect)
   let text=NSAttributedString(string:"\(Int(v*100))",attributes:[.font:NSFont.systemFont(ofSize:36,weight:.light),.foregroundColor:NSColor.labelColor])
   let numberX:CGFloat=right ? bounds.width-84 : 28
   text.draw(at:NSPoint(x:numberX,y:39))
   ("%" as NSString).draw(at:NSPoint(x:numberX+text.size().width,y:58),withAttributes:[.font:NSFont.systemFont(ofSize:15),.foregroundColor:NSColor.labelColor])
  }
 }
 override func mouseDown(with event:NSEvent) { update(event); while let e=window?.nextEvent(matching:[.leftMouseDragged,.leftMouseUp]) { if e.type == .leftMouseUp { break }; update(e) } }
 private func update(_ event:NSEvent) {
  let p=convert(event.locationInWindow,from:nil)
  guard p.x < 25 || p.x > bounds.width-25 else { return }
  let v=Double(min(1,max(0,1-(p.y-12)/(bounds.height-24))))
  if (p.x>bounds.midX) != swapped { _=system.volume(v) } else { _=system.brightness(v) }
  needsDisplay=true; changed()
 }
}

final class ControlPanel:NSView {
 let owner:AppDelegate
 var showingSettings=false, mediaExpanded=true
 var card:LevelCard?, statusLabel:NSTextField?, sensitivityLabel:NSTextField?, edgeLabel:NSTextField?
 override var isFlipped:Bool { true }
 init(owner:AppDelegate) { self.owner=owner; super.init(frame:NSRect(x:0,y:0,width:320,height:532)); rebuild() }
 required init?(coder:NSCoder) { fatalError() }
 override func draw(_ dirtyRect:NSRect) {
  (effectiveAppearance.bestMatch(from:[.aqua,.darkAqua]) == .darkAqua ? NSColor(calibratedWhite:0.12,alpha:1) : NSColor(calibratedWhite:0.92,alpha:1)).setFill(); bounds.fill()
 }
 func place(_ view:NSView,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat) { view.frame=NSRect(x:x,y:y,width:w,height:h); addSubview(view) }
 @discardableResult func text(_ value:String,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ size:CGFloat=12,_ weight:NSFont.Weight = .regular)->NSTextField {
  let l=NSTextField(labelWithString:value); l.font = .systemFont(ofSize:size,weight:weight); l.lineBreakMode = .byTruncatingTail
  place(l,x,y,w,size+6); return l
 }
 func rule(_ y:CGFloat) { let v=NSBox(); v.boxType = .separator; place(v,14,y,292,1) }
 func save(_ key:String,_ value:Any) { defaults.set(value,forKey:key); owner.loadOptions(); owner.resetGesture() }
 func feature(_ title:String,_ detail:String,_ symbol:String,_ key:String,_ y:CGFloat) {
  let on=defaults.bool(forKey:key)
  place(PanelIcon(symbol,enabled:on),14,y+1,28,28)
  text(title,51,y,245,13,.medium)
  text(detail,51,y+18,230,11).textColor = .labelColor
  place(PanelToggle(on:on,title:title) { [weak self] value in self?.save(key,value); self?.rebuild() },280,y+7,27,19)
 }
 func header(_ title:String, ready:Bool=false) {
  let icon=NSImageView(); icon.image=NSImage(contentsOf:Bundle.main.url(forResource:"AppIcon",withExtension:"icns") ?? URL(fileURLWithPath:"")); place(icon,17,14,18,18)
  text(title,47,16,170,14,.semibold)
  if ready {
   let enabled=owner.engine.options.enabled, trusted=AXIsProcessTrusted()
   let dot=NSView(); dot.wantsLayer=true; dot.layer?.backgroundColor=(trusted && enabled ? NSColor.systemGreen : .systemOrange).cgColor; dot.layer?.cornerRadius=3; place(dot,260,21,6,6)
   statusLabel=text(trusted ? (enabled ? "Ready" : "Paused") : "Access",272,17,43,11)
  }
 }
 func rebuild() {
  subviews.forEach { $0.removeFromSuperview() }; card=nil; statusLabel=nil; sensitivityLabel=nil; edgeLabel=nil
  if showingSettings { settings() } else { main() }
 }
 func main() {
  header("TrackEdge",ready:true)
  let c=LevelCard(system:owner.system); c.swapped=owner.engine.options.swapSides; card=c; place(c,14,47,292,104)
  place(PanelIcon("hand.tap.fill",enabled:owner.haptics),14,170,28,28)
  text("Haptic Feedback",51,169,170,13,.medium); text("Clicks as you slide",51,187,180,11)
  let p=NSPopUpButton(); p.addItems(withTitles:["Off","Light","Medium","Strong"]); p.selectItem(at:owner.haptics ? owner.hapticStrength+1 : 0); p.controlSize = .small; p.font = .systemFont(ofSize:11); p.target=self; p.action=#selector(hapticChanged(_:)); place(p,233,176,74,22)
  feature("Quick Mute","Double-tap the top-right corner","speaker.slash.fill","quickMute",213)
  feature("Media Strip","Swipe the bottom edge to skip songs","forward.fill","media",256)
  place(PanelButton("",symbol:mediaExpanded ? "chevron.down" : "chevron.right") { [weak self] in guard let self else { return }; self.mediaExpanded.toggle(); self.rebuild() },122,258,18,14)
  if mediaExpanded {
   text("Tap to Play or Pause",51,299,230,13,.medium); text("Clicks near the edge can set it off",51,317,240,11)
   let toggle=PanelToggle(on:defaults.bool(forKey:"tapToPlay"),title:"Tap to Play or Pause") { [weak self] in self?.save("tapToPlay",$0) }; toggle.isEnabled=owner.engine.options.media; place(toggle,280,307,27,19)
  }
  rule(346)
  place(PanelIcon("dial.low",enabled:false),14,361,28,28); text("Sensitivity",51,369,180,13,.medium)
  sensitivityLabel=text(String(format:"%.1f×",owner.engine.options.sensitivity),264,370,43,12,.medium); sensitivityLabel?.alignment = .right
  place(PanelSlider(value:owner.engine.options.sensitivity,min:0.5,max:4,title:"Sensitivity") { [weak self] in self?.save("sensitivity",$0); self?.sensitivityLabel?.stringValue=String(format:"%.1f×",$0) },51,391,255,22)
  place(PanelIcon("arrow.left.and.right",enabled:false),14,423,28,28); text("Edge Width",51,431,180,13,.medium)
  edgeLabel=text(String(format:"%.0f%%",owner.engine.options.edgeWidth*100),264,432,43,12,.medium); edgeLabel?.alignment = .right
  place(PanelSlider(value:owner.engine.options.edgeWidth,min:0.03,max:0.18,title:"Edge Width") { [weak self] in self?.save("edgeWidth",$0); self?.edgeLabel?.stringValue=String(format:"%.0f%%",$0*100) },51,453,255,22)
  rule(491)
  place(PanelButton("Settings",symbol:"gearshape") { [weak self] in self?.showingSettings=true; self?.rebuild() },14,499,85,24)
  place(PanelButton("",symbol:"ellipsis.circle") { [weak self] in self?.more() },255,499,22,24)
  place(PanelButton("",symbol:"power") { [weak self] in self?.owner.quit() },285,499,22,24)
 }
 func settings() {
  header("Settings")
  text("Edge Gestures",16,48,250,11,.semibold)
  feature("Swap Sides",owner.engine.options.swapSides ? "Left: Volume · Right: Brightness" : "Left: Brightness · Right: Volume","arrow.left.arrow.right","swapSides",72)
  feature("Bottom Quarter Only","Ignore touches above the lower 25%","rectangle.bottomthird.inset.filled","bottomQuarter",115)
  place(PanelIcon("option",enabled:owner.engine.options.modifier != 0),14,159,28,28)
  text("Require Fn or ⌥",51,158,230,13,.medium); text("Only slide while holding a modifier",51,176,230,11)
  place(PanelToggle(on:owner.engine.options.modifier != 0,title:"Require Fn or Option") { [weak self] value in self?.save("modifier",value ? 3 : 0); self?.rebuild() },280,165,27,19)
  rule(203)
  text("While Sliding",16,216,250,11,.semibold)
  feature("Freeze Cursor","Pointer stays put while sliding","cursorarrow","freezeCursor",240)
  feature("Fine Control","Hold ⇧⌥ for quarter steps","sun.max.fill","fineControl",283)
  rule(326)
  text("General",16,338,250,11,.semibold)
  place(PanelIcon("circle.lefthalf.filled",enabled:false),14,359,28,28); text("Appearance",51,365,150,13,.medium)
  let appearance=NSSegmentedControl(labels:["Light","Dark"],trackingMode:.selectOne,target:self,action:#selector(appearanceChanged(_:))); appearance.segmentStyle = .rounded; appearance.controlSize = .small; appearance.selectedSegment=owner.appearance == 2 ? 1 : 0; place(appearance,229,365,78,20)
  let login=SMAppService.mainApp.status == .enabled
  place(PanelIcon("power",enabled:login),14,397,28,28); text("Open at Login",51,404,200,13,.medium)
  place(PanelToggle(on:login,title:"Open at Login") { [weak self] value in
   guard let self else { return }; let button=NSButton(); button.state=value ? .on : .off; self.owner.loginChanged(button); self.rebuild()
  },280,404,27,19)
  rule(491)
  place(PanelButton("Back",symbol:"chevron.left") { [weak self] in self?.showingSettings=false; self?.rebuild() },14,499,60,24)
  text("Version 0.2.0",130,505,110,10).textColor = .secondaryLabelColor
  place(PanelButton("",symbol:"ellipsis.circle") { [weak self] in self?.more() },255,499,22,24)
  place(PanelButton("",symbol:"power") { [weak self] in self?.owner.quit() },285,499,22,24)
 }
 @objc func hapticChanged(_ p:NSPopUpButton) { save("haptics",p.indexOfSelectedItem != 0); if p.indexOfSelectedItem > 0 { save("hapticStrength",p.indexOfSelectedItem-1) }; rebuild() }
 @objc func appearanceChanged(_ p:NSSegmentedControl) { save("appearance",p.selectedSegment == 0 ? 1 : 2) }
 @objc func pause() { save("enabled",!owner.engine.options.enabled); rebuild() }
 @objc func setup() { owner.showSetup() }
 func more() {
  let menu=NSMenu()
  let pause=NSMenuItem(title:owner.engine.options.enabled ? "Pause Gestures" : "Resume Gestures",action:#selector(pause),keyEquivalent:""); pause.target=self; menu.addItem(pause)
  let setup=NSMenuItem(title:"Setup & Diagnostics…",action:#selector(setup),keyEquivalent:""); setup.target=self; menu.addItem(setup)
  menu.popUp(positioning:nil,at:NSPoint(x:254,y:499),in:self)
 }
 func refresh() { statusLabel?.stringValue=AXIsProcessTrusted() ? (owner.engine.options.enabled ? "Ready" : "Paused") : "Access"; card?.swapped=owner.engine.options.swapSides; card?.needsDisplay=true }
}
