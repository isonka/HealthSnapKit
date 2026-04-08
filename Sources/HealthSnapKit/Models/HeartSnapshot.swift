import Foundation

/// A single heart rate sample at a point in time.
public struct HeartSample: Sendable, Codable, Equatable {
    /// When the sample was recorded.
    public let timestamp: Date
    /// Beats per minute.
    public let bpm: Double

    /// Creates a heart rate sample.
    public init(timestamp: Date, bpm: Double) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}

/// Heart rate and variability summary for a calendar day.
public struct HeartSnapshot: Sendable, Codable, Equatable {
    /// The calendar day this snapshot represents.
    public let date: Date
    /// Average heart rate from discrete samples (beats per minute).
    public let averageBPM: Double
    /// Resting heart rate if available (beats per minute).
    public let restingBPM: Double?
    /// Heart rate variability (SDNN) if available (milliseconds).
    public let hrvSDNN: Double?
    /// Chronological heart rate samples for the day.
    public let samples: [HeartSample]

    /// Creates a heart snapshot with optional resting HR and HRV.
    public init(
        date: Date,
        averageBPM: Double,
        restingBPM: Double?,
        hrvSDNN: Double?,
        samples: [HeartSample]
    ) {
        self.date = date
        self.averageBPM = averageBPM
        self.restingBPM = restingBPM
        self.hrvSDNN = hrvSDNN
        self.samples = samples
    }
}
