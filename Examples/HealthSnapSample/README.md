# HealthSnapSample

Minimal **SwiftUI** iOS app that depends on the parent **HealthSnapKit** package via a local Swift Package reference (`../..`).

## Open and run

1. Open `HealthSnapSample.xcodeproj` in Xcode.
2. Select the **HealthSnapSample** scheme and an **iPhone** simulator (or a physical device).
3. Set your **Team** under *Signing & Capabilities* if Xcode prompts for code signing.
4. Build and run (**⌘R**).

## What it does

- **Data source** — **HealthKit** uses the real store (authorize first). **Mock** fills the list with static `ActivitySnapshot` / `HeartSnapshot` / `SleepSnapshot` / `BodySnapshot` values so you can demo the UI in Simulator without data.
- **Request Health access** calls `HealthSnapKit.requestAuthorization()` (disabled in Mock mode).
- **Load samples** fetches today’s activity and heart summaries, the last few nights of sleep, and the latest body metrics—or applies the mock snapshots when Mock is selected.

Use a **real iPhone** (ideally with Apple Watch data) for meaningful HealthKit results; the Simulator often has little or no data.

## Bundle ID

Default: `dev.healthsnap.HealthSnapSample`. Change it in the target’s *General* settings if it conflicts with another app on your device.
