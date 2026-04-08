# HealthSnapKit

A small Swift library that wraps [HealthKit](https://developer.apple.com/documentation/healthkit) with an async/await API. It exposes **activity**, **sleep**, **heart rate**, **HRV**, and **body metrics** through unified `Sendable`/`Codable` models so you spend less time on query boilerplate and authorization wiring.

## Why this exists

HealthKit is powerful but repetitive: predicate construction, `HKStatisticsQuery` / `HKSampleQuery` completion handlers, calendar-day boundaries, and permission sets for each data type. HealthSnapKit centralizes that behind typed providers and snapshots you can drop into SwiftUI (`@Observable` facade) or any async Swift code.

## Requirements

- **iOS 17+**
- **Swift 5.9+** (SwiftPM tools version 5.9)
- **Xcode / app target** with the **HealthKit** capability enabled (`com.apple.developer.healthkit` in your entitlements)

The package itself has **no third-party dependencies** (HealthKit + Foundation only).

## Installation (Swift Package Manager)

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/HealthSnapKit.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourAppTarget",
        dependencies: [
            .product(name: "HealthSnapKit", package: "HealthSnapKit"),
        ]
    ),
]
```

In Xcode: **File → Add Package Dependencies…** and enter your repository URL.

## Usage

```swift
import HealthSnapKit

let kit = HealthSnapKit()

// Request read access (all domains, or pass a subset)
try await kit.requestAuthorization()
try await kit.requestAuthorization(reading: [.activity, .sleep, .heart, .body])

// Today / specific day / ranges
let activityToday = try await kit.activity.today()
let activityDay = try await kit.activity.date(Date())
let activityWeek = try await kit.activity.last(days: 7)

let sleepRecent = try await kit.sleep.last(nights: 7)
let sleepOneNight = try await kit.sleep.today()

let heartToday = try await kit.heart.today()
let heartLastWeek = try await kit.heart.last(days: 7)

let body = try await kit.body.latest()
let bodyAsOfDay = try await kit.body.date(Date())
```

### Fine-grained authorization

`HealthDataDomain` groups related HealthKit types: `.activity`, `.sleep`, `.heart`, `.body`. Pass a `Set` to `requestAuthorization(reading:)`.

### Errors

`HealthSnapError` covers the common cases: `notAvailable`, `notAuthorized`, `noData`, and `queryFailed(Error)`.

## Model reference

| Type | Field | Description / unit |
|------|--------|----------------------|
| **ActivitySnapshot** | `date` | Calendar day (start-of-day semantics from the user’s calendar) |
| | `steps` | Count (steps) |
| | `activeCalories` | Kilocalories (kcal) |
| | `totalCalories` | kcal (active + basal energy for that day) |
| | `distanceMeters` | Meters |
| | `exerciseMinutes` | Minutes (Apple Exercise Time) |
| | `standHours` | Count of stand-hour samples with “stood” |
| **SleepSnapshot** | `date` | Night anchor (typically wake-up calendar day) |
| | `totalDuration` | Seconds asleep (excluding awake segments) |
| | `efficiency` | 0…1 (asleep divided by in-bed time when in-bed data exists) |
| | `stages` | `SleepStages` (all seconds) |
| **SleepStages** | `awake`, `rem`, `core`, `deep` | Seconds per stage |
| **HeartSnapshot** | `date` | Calendar day |
| | `averageBPM` | Beats per minute |
| | `restingBPM` | BPM, optional |
| | `hrvSDNN` | Milliseconds (SDNN), optional |
| | `samples` | `[HeartSample]` |
| **HeartSample** | `timestamp` | Sample time |
| | `bpm` | Beats per minute |
| **BodySnapshot** | `date` | Latest sample time among populated fields |
| | `weightKg` | Kilograms, optional |
| | `bmi` | Dimensionless index, optional |
| | `bodyFatPercentage` | Percent (0–100 scale), optional |

## Providers

Each provider offers `today()`, `date(_:)`, and `range(_:)` where it applies. **Activity** and **heart** add `last(days:)`. **Sleep** adds `last(nights:)`. **Body** also exposes `latest()` for the most recent samples.

## Devices and the simulator

HealthKit behavior depends on hardware and user data. **Heart rate, HRV, workouts, and much other data are unreliable or absent on the Simulator** compared to a physical iPhone (often paired with Apple Watch). Treat the simulator as useful for wiring and UI; **validate health features on a real device** with data in the Health app.

## Documentation

- Apple — [HealthKit](https://developer.apple.com/documentation/healthkit)

## Related

Other tooling in the same problem space (trimming and shipping on-device context for agents or LLMs):

- [context-trimmer](https://github.com/search?q=context-trimmer&type=repositories)
- [mobile-context-trimmer](https://github.com/search?q=mobile-context-trimmer&type=repositories)

Replace those links with your canonical repository URLs when you publish them.

## License

MIT — see [LICENSE](LICENSE).
