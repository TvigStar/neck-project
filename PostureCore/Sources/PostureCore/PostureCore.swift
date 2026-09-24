import Foundation

/// Platform-independent posture detection logic.
/// No iOS framework imports, so it builds and tests on Windows too.
public enum PostureCore {
    public static let version = "0.1.0"

    public static func degrees(fromRadians radians: Double) -> Double {
        radians * 180 / .pi
    }
}
