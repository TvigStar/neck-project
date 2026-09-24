import CoreMotion
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let motion = HeadphoneMotionService()
    let probe = BackgroundProbe()
    @ObservationIgnored let audio = AudioController()

    /// Spike helper: beep periodically, driven by motion samples, to prove beeps work while locked.
    var periodicBeep = false
    var periodicBeepInterval = 30.0
    @ObservationIgnored private var lastBeepAt = Date.distantPast

    private(set) var isMonitoring = false

    init() {
        motion.onSample = { [weak self] _ in
            self?.handleSample()
        }
    }

    func startMonitoring() {
        audio.startKeepAlive()
        motion.start()
        isMonitoring = motion.isRunning
    }

    func stopMonitoring() {
        motion.stop()
        audio.stopKeepAlive()
        isMonitoring = false
    }

    private func handleSample() {
        let now = Date.now
        probe.record(at: now)
        if periodicBeep, now.timeIntervalSince(lastBeepAt) >= periodicBeepInterval {
            lastBeepAt = now
            audio.beep()
        }
    }
}
