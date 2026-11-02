import AppKit
import CoreAudio
import AudioToolbox
import ServiceManagement
final class SystemControls {
 typealias GetBrightness = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
 typealias SetBrightness = @convention(c) (UInt32, Float) -> Int32
 private let library = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
 private var getBrightness: GetBrightness? {
  guard let library, let s=dlsym(library,"DisplayServicesGetBrightness") else { return nil }
  return unsafeBitCast(s,to:GetBrightness.self)
 }
 private var setBrightness: SetBrightness? {
  guard let library, let s=dlsym(library,"DisplayServicesSetBrightness") else { return nil }
  return unsafeBitCast(s,to:SetBrightness.self)
 }
 var display: CGDirectDisplayID {
  NSScreen.screens.first(where: { CGDisplayIsBuiltin(($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32) ?? 0) != 0 }).flatMap { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 } ?? CGMainDisplayID()
 }
 var brightness: Double? {
  var v: Float=0
  guard let getBrightness, getBrightness(display,&v)==0 else { return nil }
  return Double(v)
 }
 @discardableResult func brightness(_ value: Double) -> Bool { setBrightness?(display,Float(value)) == 0 }
 private var output: AudioDeviceID {
  var id=AudioDeviceID(0), size=UInt32(MemoryLayout<AudioDeviceID>.size)
  var address=AudioObjectPropertyAddress(mSelector:kAudioHardwarePropertyDefaultOutputDevice,mScope:kAudioObjectPropertyScopeGlobal,mElement:kAudioObjectPropertyElementMain)
  AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),&address,0,nil,&size,&id)
  return id
 }
 private func read(_ selector: AudioObjectPropertySelector, channel: UInt32 = 0) -> Double? {
  var addr=AudioObjectPropertyAddress(mSelector:selector,mScope:kAudioDevicePropertyScopeOutput,mElement:channel)
  var v: Float32=0, size=UInt32(MemoryLayout<Float32>.size)
  guard AudioObjectGetPropertyData(output,&addr,0,nil,&size,&v)==0 else { return nil }; return Double(v)
 }
 var volume: Double? { read(kAudioHardwareServiceDeviceProperty_VirtualMainVolume) ?? read(kAudioDevicePropertyVolumeScalar) ?? read(kAudioDevicePropertyVolumeScalar,channel:1) }
 @discardableResult func volume(_ value: Double) -> Bool {
  for selector in [kAudioHardwareServiceDeviceProperty_VirtualMainVolume,kAudioDevicePropertyVolumeScalar] {
   var addr=AudioObjectPropertyAddress(mSelector:selector,mScope:kAudioDevicePropertyScopeOutput,mElement:0)
   var v=Float32(value)
   if AudioObjectSetPropertyData(output,&addr,0,nil,UInt32(MemoryLayout<Float32>.size),&v)==0 { return true }
  }
  var success=false
  for ch: UInt32 in [1,2] {
   var addr=AudioObjectPropertyAddress(mSelector:kAudioDevicePropertyVolumeScalar,mScope:kAudioDevicePropertyScopeOutput,mElement:ch)
   var v=Float32(value)
   if AudioObjectSetPropertyData(output,&addr,0,nil,4,&v)==0 { success=true }
  }
  return success
 }
 // Posting the same media-key events as the keyboard lets macOS draw its own OSD.
 func key(_ code: Int, fine: Bool = false) {
  for down in [true,false] {
   var flags=NSEvent.ModifierFlags(rawValue:down ? 0xa00 : 0xb00)
   if fine { flags.formUnion([.shift,.option]) }
   let data=(code << 16) | ((down ? 0xa : 0xb) << 8)
   NSEvent.otherEvent(with:.systemDefined,location:.zero,modifierFlags:flags,timestamp:ProcessInfo.processInfo.systemUptime,windowNumber:0,context:nil,subtype:8,data1:data,data2:-1)?.cgEvent?.post(tap:.cghidEventTap)
  }
 }
 func act(_ action: GestureAction) {
  switch action {
   case let .volume(ticks,fine): for _ in 0..<min(abs(ticks),32) { key(ticks>0 ? 0 : 1,fine:fine) }
   case let .brightness(ticks,fine): for _ in 0..<min(abs(ticks),32) { key(ticks>0 ? 2 : 3,fine:fine) }
   case .mute: key(7)
   case .playPause: key(16)
   case .next: key(17)
   case .previous: key(18)
  }
 }
}
