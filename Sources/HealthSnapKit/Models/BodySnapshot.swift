import Foundation

/// Latest known body composition metrics from HealthKit.
public struct BodySnapshot: Sendable, Codable, Equatable {
    /// Date of the most recent included sample.
    public let date: Date
    /// Body mass in kilograms, if present.
    public let weightKg: Double?
    /// Body mass index, if present.
    public let bmi: Double?
    /// Body fat percentage (0–100 scale), if present.
    public let bodyFatPercentage: Double?

    /// Creates a body metrics snapshot.
    public init(date: Date, weightKg: Double?, bmi: Double?, bodyFatPercentage: Double?) {
        self.date = date
        self.weightKg = weightKg
        self.bmi = bmi
        self.bodyFatPercentage = bodyFatPercentage
    }
}
