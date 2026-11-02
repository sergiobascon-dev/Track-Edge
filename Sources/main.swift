import AppKit
import ApplicationServices
import ServiceManagement

let defaults=UserDefaults.standard
var application: AppDelegate!
func receiveTouch(_ count: Int32,_ identifier: Int32,_ x: Double,_ y: Double,_ time: Double) {
 DispatchQueue.main.async { application?.touch(Int(count),Int(identifier),x,y,time) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
 let engine=GestureEngine(), system=SystemControls()
 let cursor=CursorLock()
 var status: NSStatusItem!, popover=NSPopover(), settingsWindow: NSWindow?
 var content: NSStackView!, permissionLabel: NSTextField!, liveLabel: NSTextField!
 var volumeSlider: NSSlider!, brightnessSlider: NSSlider!
 var panel:ControlPanel!
 var trackpadLabel="Iniciando…", timer: Timer?, eventTap: CFMachPort?, tapSource: CFRunLoopSource?
 var capturedFrames=0
 var lastFrameAt=0.0
 var lastHaptic=0.0, lastTouch="Todavía no se han recibido contactos"
 var haptics=true, hapticStrength=1, appearance=0
 var paused=false

 func applicationDidFinishLaunching(_ notification: Notification) {
  NSApp.setActivationPolicy(.accessory)
  defaults.register(defaults:["enabled":true,"quickMute":true,"media":true,"tapToPlay":false,"fineControl":true,"freezeCursor":true,"edgeWidth":0.08,"sensitivity":1.5,"haptics":true])
  loadOptions()
  engine.emit = { [weak self] action in
   guard let self else { return }; self.system.act(action)
   if self.haptics && ProcessInfo.processInfo.systemUptime-self.lastHaptic > 0.045 {
    let pattern: NSHapticFeedbackManager.FeedbackPattern = self.hapticStrength == 0 ? .alignment : (self.hapticStrength == 2 ? .levelChange : .generic)
    if !EBHaptic(Int32(self.hapticStrength)) { NSHapticFeedbackManager.defaultPerformer.perform(pattern,performanceTime:.now) }
    self.lastHaptic=ProcessInfo.processInfo.systemUptime
   }
  }
  status=NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
  status.button?.image=StatusIcon.make()
  status.button?.target=self; status.button?.action=#selector(togglePopover)
  status.button?.toolTip="TrackEdge · Volumen y brillo desde el trackpad"
  popover.behavior = .transient
  buildPopover()
  startHardware()
  NSWorkspace.shared.notificationCenter.addObserver(self,selector:#selector(woke),name:NSWorkspace.didWakeNotification,object:nil)
  timer=Timer.scheduledTimer(withTimeInterval:0.6,repeats:true) { [weak self] _ in
   guard let self else { return }
   if AXIsProcessTrusted() && self.eventTap == nil { self.installTap(); if EBDeviceCount()==0 { self.startHardware() } }
   if self.engine.capturesPointer && ProcessInfo.processInfo.systemUptime-self.lastFrameAt > 0.5 { self.resetGesture() }
   if self.popover.isShown { self.refresh() }
  }
  if !defaults.bool(forKey:"hasOpened") {
   defaults.set(true,forKey:"hasOpened"); showSetup()
  } else { DispatchQueue.main.async { self.togglePopover() } }
 }
 func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { if !popover.isShown { togglePopover() }; return true }
 func resetGesture() { engine.reset(); cursor.stop() }
 func loadOptions() {
  engine.options.enabled=defaults.bool(forKey:"enabled")
  engine.options.swapSides=defaults.bool(forKey:"swapSides")
  engine.options.bottomQuarter=defaults.bool(forKey:"bottomQuarter")
  engine.options.quickMute=defaults.bool(forKey:"quickMute")
  engine.options.media=defaults.bool(forKey:"media")
  engine.options.tapToPlay=defaults.bool(forKey:"tapToPlay")
  engine.options.fineControl=defaults.bool(forKey:"fineControl")
  engine.options.freezeCursor=defaults.bool(forKey:"freezeCursor")
  engine.options.modifier=defaults.integer(forKey:"modifier")
  engine.options.edgeWidth=defaults.double(forKey:"edgeWidth")
  engine.options.sensitivity=defaults.double(forKey:"sensitivity")
  haptics=defaults.bool(forKey:"haptics"); hapticStrength=defaults.integer(forKey:"hapticStrength"); appearance=defaults.integer(forKey:"appearance")
  applyAppearance()
 }
 func applyAppearance() { NSApp.appearance=appearance == 0 ? nil : NSAppearance(named:appearance == 1 ? .aqua : .darkAqua) }
 func startHardware() {
  resetGesture()
  let ok=EBStart(receiveTouch)
  trackpadLabel=ok ? "Trackpad conectado · \(EBDeviceCount()) dispositivo(s)" : "Trackpad sin acceso · revisa los permisos"
  installTap()
 }
 @objc func woke() { DispatchQueue.main.asyncAfter(deadline:.now()+1) { [weak self] in self?.startHardware() } }
 func installTap() {
  guard eventTap == nil, AXIsProcessTrusted() else { return }
  let mask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue) | (1 << CGEventType.scrollWheel.rawValue)
  let callback: CGEventTapCallBack = { _,type,event,context in
   guard let context else { return Unmanaged.passUnretained(event) }
   let owner=Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
   if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
    if let tap=owner.eventTap { CGEvent.tapEnable(tap:tap,enable:true) }
    return Unmanaged.passUnretained(event)
   }
   if owner.engine.capturesPointer {
    if type == .scrollWheel { return nil }
    owner.cursor.constrain(event)
   }
   return Unmanaged.passUnretained(event)
  }
  // A session tap runs after WindowServer may have advanced the physical cursor.
  // A HID tap rewrites the absolute position and deltas before that integration.
  eventTap=CGEvent.tapCreate(tap:.cghidEventTap,place:.headInsertEventTap,options:.defaultTap,eventsOfInterest:mask,callback:callback,userInfo:Unmanaged.passUnretained(self).toOpaque())
  if let eventTap {
   tapSource=CFMachPortCreateRunLoopSource(kCFAllocatorDefault,eventTap,0)
   CFRunLoopAddSource(CFRunLoopGetMain(),tapSource,.commonModes); CGEvent.tapEnable(tap:eventTap,enable:true)
  }
 }
 func touch(_ count: Int,_ id: Int,_ x: Double,_ y: Double,_ time: Double) {
  lastFrameAt=ProcessInfo.processInfo.systemUptime
  guard AXIsProcessTrusted(), !popover.isShown, settingsWindow?.isVisible != true else { resetGesture(); return }
  if count>0 { lastTouch=String(format:"Contacto: x %.2f · y %.2f",x,y) }
  let flags=NSEvent.modifierFlags
  engine.frame(count:count,id:id,x:x,y:y,time:time,option:flags.contains(.option),fn:flags.contains(.function),shift:flags.contains(.shift))
  cursor.setLocked(engine.capturesPointer)
  if engine.capturesPointer { capturedFrames += 1 }
 }
 func buildPopover() {
  panel=ControlPanel(owner:self)
  let vc=NSViewController(); vc.view=panel
  popover.contentViewController=vc; popover.contentSize=NSSize(width:320,height:532)
 }
 @objc func togglePopover() {
  if popover.isShown { popover.performClose(nil) }
  else if let button=status.button {
   resetGesture(); panel.rebuild(); refresh()
   popover.show(relativeTo:button.bounds,of:button,preferredEdge:.minY)
  }
 }
 func refresh() { panel?.refresh() }
 @objc func mute() { system.key(7) }
 @objc func play() { system.key(16) }
 @objc func previous() { system.key(18) }
 @objc func next() { system.key(17) }
 @objc func quit() { NSApp.terminate(nil) }
 func error(_ message: String) { let a=NSAlert(); a.messageText=message; a.runModal() }
 @objc func loginChanged(_ b: NSButton) {
  do { if b.state == .on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
  catch { b.state=SMAppService.mainApp.status == .enabled ? .on : .off; self.error("No se pudo cambiar el inicio automático: \(error.localizedDescription)") }
 }
 @objc func showSetup() {
  popover.performClose(nil); resetGesture(); NSApp.activate(ignoringOtherApps:true)
  let a=NSAlert(); a.messageText="TrackEdge · Primeros pasos"
  a.informativeText="1. Concede Accesibilidad a TrackEdge en Ajustes del Sistema → Privacidad y seguridad → Accesibilidad. Si macOS solicita Monitorización de entrada, autorízala también y reinicia la app.\n\n2. Cierra los paneles y desliza un dedo por el borde derecho para el volumen y por el izquierdo para el brillo.\n\n3. Doble toque arriba a la derecha: silencio. Desliza abajo: cambia de pista. ⇧⌥: pasos finos.\n\n\(trackpadLabel)\n\(lastTouch)\nFotogramas capturados: \(capturedFrames) · bloqueo: \(cursor.lastError.rawValue) · filtro HID: \(eventTap != nil)\nAccesibilidad: \(AXIsProcessTrusted() ? "concedida" : "pendiente")\n\nLa respuesta háptica requiere un trackpad compatible. Los gestos usan una interfaz interna de macOS; una actualización del sistema puede requerir adaptar la app."
  a.addButton(withTitle:"Entendido"); a.addButton(withTitle:"Abrir Accesibilidad"); a.addButton(withTitle:"Reconectar trackpad")
  let result=a.runModal()
  if result == .alertSecondButtonReturn {
   let options=[kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String:true] as CFDictionary
   _=AXIsProcessTrustedWithOptions(options)
   NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
  } else if result == .alertThirdButtonReturn { startHardware() }
 }
 func applicationWillTerminate(_ notification: Notification) {
  resetGesture(); timer?.invalidate(); EBStop()
  if let eventTap { CFMachPortInvalidate(eventTap) }
 }
}
if CommandLine.arguments.contains("--self-check") {
 _ = NSApplication.shared
 let controls=SystemControls()
 print("TrackEdge self-check")
 print("Accessibility: \(AXIsProcessTrusted())")
 print("Volume readable: \(controls.volume != nil)")
 print("Brightness readable: \(controls.brightness != nil)")
 print("Multitouch framework: \(dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) != nil)")
 let opened=EBStart(receiveTouch)
 print(String(cString: EBDeviceInfo()))
 print("Trackpad opened: \(opened), devices: \(EBDeviceCount())")
 EBStop()
 exit(0)
}
if CommandLine.arguments.contains("--render-panels") {
 _ = NSApplication.shared
 defaults.register(defaults:["enabled":true,"quickMute":true,"media":true,"tapToPlay":false,"fineControl":true,"freezeCursor":true,"edgeWidth":0.08,"sensitivity":1.5,"haptics":true])
 let owner=AppDelegate(); owner.loadOptions()
 let panel=ControlPanel(owner:owner)
 let window=NSWindow(contentRect:panel.bounds,styleMask:.borderless,backing:.buffered,defer:false)
 window.contentView=panel
 let dir=URL(fileURLWithPath:CommandLine.arguments.last!)
 try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
 for dark in [false,true] {
  NSApp.appearance=NSAppearance(named:dark ? .darkAqua : .aqua)
  window.appearance=NSApp.appearance
  for settings in [false,true] {
   panel.showingSettings=settings; panel.rebuild(); panel.layoutSubtreeIfNeeded(); panel.display()
   let bitmap=panel.bitmapImageRepForCachingDisplay(in:panel.bounds)!
   panel.cacheDisplay(in:panel.bounds,to:bitmap)
   let name="\(settings ? "settings" : "menu")-\(dark ? "dark" : "light").png"
   try bitmap.representation(using:.png,properties:[:])!.write(to:dir.appendingPathComponent(name))
  }
 }
 exit(0)
}
atexit { _=CGAssociateMouseAndMouseCursorPosition(1) }
let app=NSApplication.shared
application=AppDelegate()
app.delegate=application
app.run()
