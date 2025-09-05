// SwiftMathSmokeTest.swift
#if DEBUG
#if canImport(SwiftMath)
import SwiftMath

// If SwiftMath is not linked, this file won't compile under the canImport gate.
// If it is linked, constructing MTMathUILabel succeeds at compile-time.
@inline(__always)
func _swiftMathSmokeTest() {
    _ = MTMathUILabel()
}
#endif
#endif
