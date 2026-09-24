import SwiftUI
import PostureCore

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Headphones") {
                    LabeledContent("Motion available", value: model.motion.isAvailable ? "yes" : "no")
                    LabeledContent("Authorization", value: model.motion.authorization)
                    LabeledContent("Connection", value: model.motion.connection.rawValue)
                    if let error = model.motion.lastError {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section("Attitude") {
                    angleRow("Pitch", model.motion.pitch)
                    angleRow("Roll", model.motion.roll)
                    angleRow("Yaw", model.motion.yaw)
                }

                Section {
                    if model.isMonitoring {
                        Button("Stop monitoring", role: .destructive) { model.stopMonitoring() }
                    } else {
                        Button("Start monitoring") { model.startMonitoring() }
                    }
                    Button("Test beep") { model.audio.beep() }
                    Toggle("Beep every \(Int(model.periodicBeepInterval)) s", isOn: $model.periodicBeep)
                }

                Section("Background probe") {
                    LabeledContent("Samples", value: "\(model.probe.totalSamples)")
                    LabeledContent("In background", value: "\(model.probe.backgroundSamples)")
                    LabeledContent("Rate", value: String(format: "%.1f Hz", model.probe.sampleRate))
                    Button("Reset") { model.probe.reset() }
                }

                if !model.probe.gaps.isEmpty {
                    Section("Gaps > 2 s") {
                        ForEach(model.probe.gaps.prefix(20)) { gap in
                            LabeledContent(
                                gap.start.formatted(date: .omitted, time: .standard),
                                value: String(format: "%.1f s%@", gap.seconds, gap.wasBackground ? " (bg)" : "")
                            )
                        }
                    }
                }
            }
            .navigationTitle("Posture")
            .monospacedDigit()
        }
    }

    private func angleRow(_ title: String, _ radians: Double) -> some View {
        LabeledContent(title, value: String(format: "%+.1f°", PostureCore.degrees(fromRadians: radians)))
    }
}
