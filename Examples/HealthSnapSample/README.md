# HealthSnapSample

Minimal **SwiftUI** iOS app that depends on the parent **HealthSnapKit** package via a local Swift Package reference (`../..`).

## Open and run

1. Open `HealthSnapSample.xcodeproj` in Xcode.
2. Select the **HealthSnapSample** scheme and an **iPhone** simulator (or a physical device).
3. Set your **Team** under *Signing & Capabilities* if Xcode prompts for code signing.
4. Build and run (**⌘R**).

## What it does

- **Request Health access** calls `HealthSnapKit.requestAuthorization()`.
- **Load samples** fetches today’s activity and heart summaries, the last few nights of sleep, and the latest body metrics, then shows them in a simple list.

Use a **real iPhone** (ideally with Apple Watch data) for meaningful HealthKit results; the Simulator often has little or no data.

## Bundle ID

Default: `dev.healthsnap.HealthSnapSample`. Change it in the target’s *General* settings if it conflicts with another app on your device.
