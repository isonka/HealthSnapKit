import Foundation

/// Time spent in each sleep stage for a single night.
public struct SleepStages: Sendable, Codable, Equatable {
    /// Time awake during the sleep session (seconds).
    public let awake: TimeInterval
    /// REM sleep duration (seconds).
    public let rem: TimeInterval
    /// Core (light) sleep duration (seconds).
    public let core: TimeInterval
    /// Deep sleep duration (seconds).
    public let deep: TimeInterval

    /// Creates stage durations in seconds.
    public init(awake: TimeInterval, rem: TimeInterval, core: TimeInterval, deep: TimeInterval) {
        self.awake = awake
        self.rem = rem
        self.core = core
        self.deep = deep
    }
}

/// Aggregated sleep metrics for one night, derived from HealthKit sleep analysis samples.
public struct SleepSnapshot: Sendable, Codable, Equatable {
    /// The night’s anchor date (typically the calendar day sleep is attributed to, e.g. wake-up day).
    public let date: Date
    /// Total time asleep (seconds), excluding awake time.
    public let totalDuration: TimeInterval
    /// Ratio of asleep time to in-bed time, from 0 through 1.
    public let efficiency: Double
    /// Per-stage durations (seconds).
    public let stages: SleepStages

    /// Creates a sleep snapshot with explicit metrics.
    public init(date: Date, totalDuration: TimeInterval, efficiency: Double, stages: SleepStages) {
        self.date = date
        self.totalDuration = totalDuration
        self.efficiency = efficiency
        self.stages = stages
    }
}
