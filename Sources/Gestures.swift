import Foundation
struct GestureOptions {
 var enabled = true, swapSides = false, bottomQuarter = false, quickMute = true
 var media = true, tapToPlay = false, fineControl = true, freezeCursor = true
 var edgeWidth = 0.08, sensitivity = 1.5
 var modifier = 0 // 0 none, 1 Option, 2 Fn, 3 either Fn or Option
 mutating func normalize() {
  edgeWidth = edgeWidth.isFinite ? min(max(edgeWidth, 0.03), 0.18) : 0.08
  sensitivity = sensitivity.isFinite ? min(max(sensitivity, 0.5), 4) : 1.5
  if !(0...3).contains(modifier) { modifier = 0 }
 }
}
enum GestureAction: Equatable {
 case volume(Int, Bool), brightness(Int, Bool), mute, playPause, next, previous
}
// Pure state machine: an edge must be touched first; interior gestures never get captured.
final class GestureEngine {
 var options = GestureOptions()
 var emit: (GestureAction) -> Void = { _ in }
 private(set) var capturesPointer = false
 var isTracking: Bool { region != 0 || blocked }
 private var lastFrameTime: Double?
 private var region = 0, finger = 0, startX = 0.0, startY = 0.0, lastY = 0.0
 private var started = 0.0, carry = 0.0, moved = false, fired = false, blocked = false
 private var lastMuteTap = -10.0
 func reset() { region = 0; carry = 0; capturesPointer = false; blocked = false; lastMuteTap = -10; lastFrameTime = nil }
 func frame(count: Int, id: Int, x: Double, y: Double, time: Double, option: Bool, fn: Bool, shift: Bool) {
  guard options.enabled else { reset(); return }
  options.normalize()
  guard time.isFinite, lastFrameTime.map({ time >= $0 }) ?? true else {
   reset(); blocked = count != 0; return
  }
  lastFrameTime = time
  let allowed = options.modifier == 0 || (options.modifier == 1 && option) || (options.modifier == 2 && fn) || (options.modifier == 3 && (option || fn))
  if count == 0 {
   if allowed && !blocked && !moved && time-started < 0.28 {
    if region == 3 {
     if time-lastMuteTap >= 0 && time-lastMuteTap < 0.35 { emit(.mute); lastMuteTap = -10 } else { lastMuteTap = time }
    } else if region == 4 && options.tapToPlay { emit(.playPause) }
   }
   if (region != 0 || blocked) && (region != 3 || moved || blocked || !allowed || time-started >= 0.28) { lastMuteTap = -10 }
   region=0; carry=0; blocked=false; capturesPointer=false; return
  }
  guard count == 1, allowed, x.isFinite, y.isFinite, (0...1).contains(x), (0...1).contains(y) else {
   region=0; capturesPointer=false; blocked=true; return
  }
  guard !blocked else { return }
  if region == 0 {
   if !(options.quickMute && x > 1-options.edgeWidth*1.8 && y > 1-options.edgeWidth*1.8) { lastMuteTap = -10 }
   finger=id; startX=x; startY=y; lastY=y; started=time; carry=0; moved=false; fired=false
   let w=options.edgeWidth
   if options.quickMute && x > 1-w*1.8 && y > 1-w*1.8 { region=3 }
   else if (!options.bottomQuarter || y <= 0.25) && x < w { region=1 }
   else if (!options.bottomQuarter || y <= 0.25) && x > 1-w { region=2 }
   else if options.media && y < w { region=4 }
   else { blocked=true; return }
   capturesPointer=options.freezeCursor
   return
  }
  guard id == finger else { region=0; capturesPointer=false; blocked=true; return }
  if abs(x-startX) > 0.025 || abs(y-startY) > 0.025 { moved=true }
  if region == 3 && moved {
   region=2; lastMuteTap = -10 // top-right sliding still controls its side
  }
  if region == 4 {
   if !fired && abs(x-startX) > 0.18 && abs(x-startX) > abs(y-startY)*1.5 {
    emit(x>startX ? .next : .previous); fired=true
   }
   return
  }
  guard region == 1 || region == 2 else { return }
  let fine=options.fineControl && shift && option
  let step = fine ? 1.0/64 : 1.0/16
  carry += (y-lastY)*options.sensitivity; lastY=y
  let ticks=Int(carry/step)
  if ticks != 0 {
   carry -= Double(ticks)*step
   let volume=(region == 2) != options.swapSides
   emit(volume ? .volume(ticks,fine) : .brightness(ticks,fine))
  }
 }
}
