# Posture

An iOS app that watches your head tilt through AirPods head tracking and gently beeps
when you've been slouching over your phone for too long.

Early prototype, a learning pet project.

## Layout
- `PostureCore/` is the detection logic as a platform-independent Swift package. It builds and tests on Windows, Linux and macOS.
- `App/` is the iOS shell (SwiftUI, CoreMotion, audio).
- `project.yml` is the [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec. The `.xcodeproj` is generated, not committed.
- `.github/workflows/build.yml` runs the tests and builds an unsigned `.ipa` on a macOS runner.

## Development without a Mac
Run the core tests locally (Windows):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/test-core.ps1
```
On macOS/Linux use `swift test --package-path PostureCore`.

## Installing a build on an iPhone
1. Push to `main` and wait for the **Build iOS** workflow (~2 min).
2. Download the `PostureApp-N` artifact (or `gh run download -n PostureApp-N`) and unzip `PostureApp.ipa`.
3. Connect the iPhone and sideload the `.ipa` with [Sideloadly](https://sideloadly.io) using your Apple ID.
4. First time only, on the iPhone:
   - Settings → General → VPN & Device Management → trust your Apple ID.
   - Settings → Privacy & Security → Developer Mode → on (requires a restart).
5. With a free Apple ID the build expires after 7 days. Sideload it again after that.

## Requirements
- iOS 17+
- AirPods with head tracking (AirPods Pro, AirPods Max, AirPods 3/4, Beats Fit Pro, …)
