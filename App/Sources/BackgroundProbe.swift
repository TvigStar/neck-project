import Foundation
import Observation
import UIKit

/// Stage 1 spike: measures whether motion samples keep arriving while the app is in the background.
/// Writes a line every 10 s to Documents/probe.csv (visible in the Files app).
@MainActor
@Observable
final class BackgroundProbe {
    struct Gap: Identifiable {
        let id = UUID()
        let start: Date
        let seconds: Double
        let wasBackground: Bool
    }

    private(set) var totalSamples = 0
    private(set) var backgroundSamples = 0
    private(set) var gaps: [Gap] = []
    private(set) var sampleRate = 0.0

    @ObservationIgnored private var lastSampleAt: Date?
    @ObservationIgnored private var windowStart = Date()
    @ObservationIgnored private var windowSamples = 0
    @ObservationIgnored private let fileURL = URL.documentsDirectory.appending(path: "probe.csv")

    private let gapThreshold = 2.0
    private let windowLength = 10.0

    init() {
        if !FileManager.default.fileExists(atPath: fileURL.path()) {
            try? "time,app_state,samples,rate_hz\n".write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func record(at now: Date = .now) {
        let isBackground = UIApplication.shared.applicationState != .active
        totalSamples += 1
        if isBackground { backgroundSamples += 1 }

        if let last = lastSampleAt, now.timeIntervalSince(last) > gapThreshold {
            gaps.insert(Gap(start: last, seconds: now.timeIntervalSince(last), wasBackground: isBackground), at: 0)
        }
        lastSampleAt = now

        windowSamples += 1
        let elapsed = now.timeIntervalSince(windowStart)
        if elapsed >= windowLength {
            sampleRate = Double(windowSamples) / elapsed
            appendLine(time: now, state: isBackground ? "background" : "active")
            windowStart = now
            windowSamples = 0
        }
    }

    func reset() {
        totalSamples = 0
        backgroundSamples = 0
        gaps = []
        lastSampleAt = nil
        windowStart = .now
        windowSamples = 0
    }

    private func appendLine(time: Date, state: String) {
        let line = "\(time.ISO8601Format()),\(state),\(windowSamples),\(String(format: "%.1f", sampleRate))\n"
        guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: Data(line.utf8))
    }
}
