import Foundation

/// A single-day summary of movement and energy metrics from HealthKit.
public struct ActivitySnapshot: Sendable, Codable, Equatable {
    /// The calendar day this snapshot represents (typically start-of-day in the user’s locale).
    public let date: Date
    /// Total step count for the day.
    public let steps: Int
    /// Active energy burned (kilocalories).
    public let activeCalories: Double
    /// Total energy burned: active plus basal (kilocalories).
    public let totalCalories: Double
    /// Walking and running distance (meters).
    public let distanceMeters: Double
    /// Apple Watch exercise minutes (minutes).
    public let exerciseMinutes: Int
    /// Stand hours achieved (count of hours with a stand goal met).
    public let standHours: Int

    /// Creates an activity snapshot with explicit field values.
    public init(
        date: Date,
        steps: Int,
        activeCalories: Double,
        totalCalories: Double,
        distanceMeters: Double,
        exerciseMinutes: Int,
        standHours: Int
    ) {
        self.date = date
        self.steps = steps
        self.activeCalories = activeCalories
        self.totalCalories = totalCalories
        self.distanceMeters = distanceMeters
        self.exerciseMinutes = exerciseMinutes
        self.standHours = standHours
    }
}
