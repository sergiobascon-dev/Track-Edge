import Foundation
import CoreGraphics
var checks=0
func expect(_ condition: @autoclosure ()->Bool,_ text: String) { checks+=1; if !condition() { fatalError("FAIL: \(text)") } }
func scenario(_ configure: (GestureEngine)->Void = {_ in},_ frames: [(Int,Double,Double,Double,Bool,Bool,Bool)]) -> ([GestureAction],GestureEngine) {
 let e=GestureEngine(); var actions=[GestureAction](); e.emit={ actions.append($0) }; configure(e)
 for (n,x,y,t,opt,fn,shift) in frames { e.frame(count:n,id:1,x:x,y:y,time:t,option:opt,fn:fn,shift:shift) }
 return (actions,e)
}
func scenario(_ frames: [(Int,Double,Double,Double,Bool,Bool,Bool)]) -> ([GestureAction],GestureEngine) { scenario({_ in},frames) }
let right=[(1,0.97,0.3,1.0,false,false,false),(1,0.97,0.4,1.1,false,false,false)]
expect(scenario(right).0 == [.volume(2,false)],"right edge volume")
let left=right.map { ($0.0,0.02,$0.2,$0.3,$0.4,$0.5,$0.6) }
expect(scenario(left).0 == [.brightness(2,false)],"left edge brightness")
expect(scenario({$0.options.swapSides=true},right).0 == [.brightness(2,false)],"swap")
expect(scenario({$0.options.bottomQuarter=true},right).0.isEmpty,"quarter blocks upper edge")
expect(!scenario(right).0.isEmpty,"normal sides work")
expect(scenario({$0.options.enabled=false},right).0.isEmpty,"pause")
expect(scenario({$0.options.modifier=1},right).0.isEmpty,"Option required")
expect(scenario({$0.options.modifier=2},right).0.isEmpty,"Fn required")
let optionRight=right.map { ($0.0,$0.1,$0.2,$0.3,true,false,false) }
expect(!scenario({$0.options.modifier=1},optionRight).0.isEmpty,"Option permits")
let fnRight=right.map { ($0.0,$0.1,$0.2,$0.3,false,true,false) }
expect(!scenario({$0.options.modifier=2},fnRight).0.isEmpty,"Fn permits")
expect(!scenario({$0.options.modifier=3},optionRight).0.isEmpty,"either modifier permits Option")
expect(!scenario({$0.options.modifier=3},fnRight).0.isEmpty,"either modifier permits Fn")
expect(scenario({$0.options.modifier=3},right).0.isEmpty,"either modifier requires a key")
let fine=right.map { ($0.0,$0.1,$0.2,$0.3,true,false,true) }
expect(scenario(fine).0 == [.volume(9,true)],"quarter steps")
expect(scenario({$0.options.fineControl=false},fine).0 == [.volume(2,false)],"fine off")
let mute=[(1,0.98,0.98,1.0,false,false,false),(0,0.0,0.0,1.1,false,false,false),(1,0.98,0.98,1.2,false,false,false),(0,0.0,0.0,1.3,false,false,false)]
expect(scenario(mute).0 == [.mute],"double tap mute")
expect(scenario({$0.options.quickMute=false},mute).0.isEmpty,"mute disabled")
let next=[(1,0.3,0.02,1.0,false,false,false),(1,0.6,0.02,1.1,false,false,false),(1,0.9,0.02,1.2,false,false,false)]
expect(scenario(next).0 == [.next],"media swipe fires once")
let previous=[(1,0.7,0.02,1.0,false,false,false),(1,0.4,0.02,1.1,false,false,false)]
expect(scenario(previous).0 == [.previous],"previous")
expect(scenario({$0.options.media=false},next).0.isEmpty,"media disabled")
let tap=[(1,0.5,0.02,1.0,false,false,false),(0,0.0,0.0,1.1,false,false,false)]
expect(scenario(tap).0.isEmpty,"tap play defaults off")
expect(scenario({$0.options.tapToPlay=true},tap).0 == [.playPause],"tap play enabled")
let interior=[(1,0.5,0.5,1.0,false,false,false),(1,0.98,0.5,1.1,false,false,false),(1,0.98,0.8,1.2,false,false,false)]
expect(scenario(interior).0.isEmpty,"no capture from interior")
expect(scenario(right).1.capturesPointer,"freeze enabled")
expect(!scenario({$0.options.freezeCursor=false},right).1.capturesPointer,"freeze disabled")
let lift=right+[(0,0.0,0.0,1.2,false,false,false)]
expect(!scenario(lift).1.capturesPointer,"lift releases freeze")
let multi=[right[0],(2,0.98,0.5,1.1,false,false,false),right[1]]
expect(scenario(multi).0.isEmpty,"multitouch cancels")
expect(!scenario(multi).1.capturesPointer,"multitouch releases freeze")
expect(scenario({$0.options.sensitivity=3},right).0 == [.volume(4,false)],"sensitivity")
let narrow=right.map { ($0.0,0.93,$0.2,$0.3,$0.4,$0.5,$0.6) }
expect(scenario({$0.options.edgeWidth=0.03},narrow).0.isEmpty,"edge width")
var connections=[Bool](), warps=[CGPoint]()
let anchor=CGPoint(x:321,y:456)
let cursor=CursorLock(locate:{ anchor },associate:{ connections.append($0); return .success },warp:{ warps.append($0); return .success })
cursor.setLocked(true)
expect(cursor.active,"lock active")
cursor.setLocked(true)
expect(connections == [false],"repeated frames do not re-anchor")
let movement=CGEvent(mouseEventSource:nil,mouseType:.mouseMoved,mouseCursorPosition:CGPoint(x:600,y:700),mouseButton:.left)!
movement.setIntegerValueField(.mouseEventDeltaX,value:90)
movement.setIntegerValueField(.mouseEventDeltaY,value:80)
cursor.constrain(movement)
expect(movement.location == anchor,"HID event fixed to anchor")
expect(movement.getIntegerValueField(.mouseEventDeltaX)==0 && movement.getIntegerValueField(.mouseEventDeltaY)==0,"both motion deltas removed")
expect(warps.last == anchor,"hardware pointer re-anchored")
cursor.stop()
expect(!cursor.active && connections == [false,true],"lift restores physical motion")
cursor.stop()
expect(connections.count == 2,"restore is idempotent")
let fallback=CursorLock(locate:{anchor},associate:{_ in .failure},warp:{_ in .success})
fallback.setLocked(true)
movement.location=CGPoint(x:800,y:900)
fallback.constrain(movement)
expect(movement.location == anchor,"HID enforcement works when background decoupling fails")
fallback.stop()
// Corrupt persisted settings must not reach a trapping Double-to-Int conversion.
for sensitivity in [Double.infinity, -Double.infinity, Double.nan, Double.greatestFiniteMagnitude] {
 expect(!scenario({ $0.options.sensitivity=sensitivity },right).0.isEmpty,"invalid sensitivity is normalized")
}
for width in [Double.infinity, -Double.infinity, Double.nan] {
 expect(!scenario({ $0.options.edgeWidth=width },right).0.isEmpty,"non-finite edge width uses default")
}
let idleBetweenMute=[mute[0],mute[1],(0,0.0,0.0,1.15,false,false,false),mute[2],mute[3]]
expect(scenario(idleBetweenMute).0 == [.mute],"idle frames between taps preserve double tap")
let interruptedMute=[mute[0],mute[1],(1,0.5,0.5,1.12,false,false,false),(0,0.0,0.0,1.15,false,false,false),mute[2],mute[3]]
expect(scenario(interruptedMute).0.isEmpty,"interior touch breaks double tap")
let reversed=[mute[0],mute[1],(1,0.98,0.98,0.5,false,false,false),(0,0.0,0.0,0.6,false,false,false)]
expect(scenario(reversed).0.isEmpty,"backwards timestamps cannot trigger mute")
let invalidTime=[right[0],(1,0.97,0.4,Double.nan,false,false,false)]
expect(!scenario(invalidTime).1.capturesPointer,"non-finite time releases pointer")
expect(scenario(invalidTime).0.isEmpty,"non-finite time emits no actions")
let unfrozen=scenario({ $0.options.freezeCursor=false },right).1
expect(unfrozen.isTracking,"watchdog tracks gestures with cursor freeze off")
unfrozen.reset()
expect(!unfrozen.isTracking,"watchdog reset clears stale gesture")
let blockedEngine=scenario(interior).1
expect(blockedEngine.isTracking,"watchdog tracks rejected contacts")
blockedEngine.reset()
expect(!blockedEngine.isTracking,"watchdog reset recovers after missing lift")
print("PASS: \(checks) gesture and cursor checks")
