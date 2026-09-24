import CoreMotion
import Observation

/// Wraps `CMHeadphoneMotionManager`: connection state, live attitude and a sample callback.
@MainActor
@Observable
final class HeadphoneMotionService: NSObject, CMHeadphoneMotionManagerDelegate {
    enum Connection: String {
        case unknown, connected, disconnected
    }

    private(set) var connection: Connection = .unknown
    private(set) var isRunning = false
    private(set) var pitch = 0.0
    private(set) var roll = 0.0
    private(set) var yaw = 0.0
    private(set) var lastError: String?

    @ObservationIgnored var onSample: (@MainActor (CMDeviceMotion) -> Void)?
    @ObservationIgnored private let manager = CMHeadphoneMotionManager()

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    var authorization: String {
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .notDetermined: "not determined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .authorized: "authorized"
        @unknown default: "unknown"
        }
    }

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        guard !isRunning else { return }
        guard manager.isDeviceMotionAvailable else {
            lastError = "Headphone motion is not available on this device"
            return
        }
        lastError = nil
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            MainActor.assumeIsolated {
                self?.handle(motion: motion, error: error)
            }
        }
        isRunning = true
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        isRunning = false
    }

    private func handle(motion: CMDeviceMotion?, error: Error?) {
        if let error {
            lastError = error.localizedDescription
            return
        }
        guard let motion else { return }
        pitch = motion.attitude.pitch
        roll = motion.attitude.roll
        yaw = motion.attitude.yaw
        onSample?(motion)
    }

    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.connection = .connected }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.connection = .disconnected }
    }
}
