import AppKit

// Filtering NSEvents alone does not freeze the hardware cursor: WindowServer moves it
// before a session event tap. Disassociate motion for the duration of an edge gesture.
final class CursorLock {
 private let locate: ()->CGPoint
 private let associate: (Bool)->CGError
 private let warp: (CGPoint)->CGError
 init(locate: @escaping ()->CGPoint = { CGEvent(source:nil)?.location ?? .zero },
      associate: @escaping (Bool)->CGError = { CGAssociateMouseAndMouseCursorPosition($0 ? 1 : 0) },
      warp: @escaping (CGPoint)->CGError = { CGWarpMouseCursorPosition($0) }) {
  self.locate=locate; self.associate=associate; self.warp=warp
 }
 private(set) var active=false
 private var anchor=CGPoint.zero
 private(set) var lastError: CGError = .success
 func setLocked(_ requested: Bool) {
  guard requested != active else { return }
  if requested {
   anchor=locate()
   lastError=associate(false)
   // Background menu-bar apps can receive success without physical decoupling.
   // The HID event filter below therefore enforces the anchor as well.
   active=true
   _=warp(anchor)
  } else {
   // Restore while still detached to avoid a jump, then reconnect physical motion.
   _=warp(anchor)
   lastError=associate(true)
   active=false
  }
 }
 func constrain(_ event: CGEvent) {
  guard active else { return }
  event.location=anchor
  event.setIntegerValueField(.mouseEventDeltaX,value:0)
  event.setIntegerValueField(.mouseEventDeltaY,value:0)
  _=warp(anchor)
 }
 func stop() { setLocked(false) }
 deinit { stop() }
}
