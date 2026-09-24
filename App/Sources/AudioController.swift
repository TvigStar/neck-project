import AVFoundation

/// Keeps the app alive in the background with a silent audio loop and plays beeps.
/// Mixes with other audio, so the user's music keeps playing.
@MainActor
final class AudioController {
    private let engine = AVAudioEngine()
    private let silencePlayer = AVAudioPlayerNode()
    private let beepPlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private lazy var silenceBuffer = makeBuffer(seconds: 1) { _ in 0 }
    private lazy var beepBuffer = makeBeep(frequency: 880, seconds: 0.25)

    private(set) var isKeepAliveRunning = false
    private(set) var lastError: String?

    init() {
        engine.attach(silencePlayer)
        engine.attach(beepPlayer)
        engine.connect(silencePlayer, to: engine.mainMixerNode, format: format)
        engine.connect(beepPlayer, to: engine.mainMixerNode, format: format)

        let center = NotificationCenter.default
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init)
            guard type == .ended else { return }
            MainActor.assumeIsolated { self?.restartIfNeeded() }
        }
        // The engine stops itself when the output route changes (e.g. AirPods connect).
        center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.restartIfNeeded() }
        }
    }

    func startKeepAlive() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            isKeepAliveRunning = true
            try startEngine()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stopKeepAlive() {
        isKeepAliveRunning = false
        silencePlayer.stop()
        beepPlayer.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func beep() {
        if !engine.isRunning {
            startKeepAlive()
        }
        beepPlayer.scheduleBuffer(beepBuffer, at: nil, options: .interrupts)
        beepPlayer.play()
    }

    private func startEngine() throws {
        if !engine.isRunning {
            try engine.start()
        }
        silencePlayer.scheduleBuffer(silenceBuffer, at: nil, options: [.loops, .interrupts])
        silencePlayer.play()
    }

    private func restartIfNeeded() {
        guard isKeepAliveRunning else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try startEngine()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func makeBeep(frequency: Double, seconds: Double) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let fade = 0.01 * sampleRate
        let total = seconds * sampleRate
        return makeBuffer(seconds: seconds) { i in
            let t = Double(i)
            let envelope = min(1, t / fade, (total - t) / fade)
            return Float(0.5 * envelope * sin(2 * .pi * frequency * t / sampleRate))
        }
    }

    private func makeBuffer(seconds: Double, sample: (Int) -> Float) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(seconds * format.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let channel = buffer.floatChannelData![0]
        for i in 0..<Int(frames) {
            channel[i] = sample(i)
        }
        return buffer
    }
}
