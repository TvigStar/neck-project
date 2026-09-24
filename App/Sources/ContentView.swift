import SwiftUI
import PostureCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Posture")
                .font(.largeTitle.bold())
            Text("PostureCore \(PostureCore.version)")
                .foregroundStyle(.secondary)
            Text("Stage 0: pipeline works 🎉")
        }
        .padding()
    }
}
