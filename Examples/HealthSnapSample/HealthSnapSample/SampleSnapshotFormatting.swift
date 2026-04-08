import Foundation
import HealthSnapKit

/// Shared strings for list rows so live HealthKit and mock data look the same.
enum SampleSnapshotFormatting {
    static func activity(_ snapshot: ActivitySnapshot) -> String {
        "Steps: \(snapshot.steps) · Active kcal: \(Int(snapshot.activeCalories)) · Distance km: \(String(format: "%.2f", snapshot.distanceMeters / 1000))"
    }

    static func heart(_ snapshot: HeartSnapshot) -> String {
        "Avg BPM: \(String(format: "%.0f", snapshot.averageBPM)) · Resting: \(snapshot.restingBPM.map { String(format: "%.0f", $0) } ?? "—") · HRV SDNN ms: \(snapshot.hrvSDNN.map { String(format: "%.1f", $0) } ?? "—") · Samples: \(snapshot.samples.count)"
    }

    static func sleepLatestNight(_ nights: [SleepSnapshot]) -> String {
        guard let last = nights.last else {
            return "No sleep sessions in the last few nights."
        }
        let hours = last.totalDuration / 3600
        let dayLabel = last.date.formatted(date: .abbreviated, time: .omitted)
        return "Latest night (\(dayLabel)): \(hours.formatted(.number.precision(.fractionLength(1)))) h asleep · efficiency \(String(format: "%.0f%%", last.efficiency * 100)) · nights: \(nights.count)"
    }

    static func body(_ snapshot: BodySnapshot) -> String {
        "Weight kg: \(snapshot.weightKg.map { String(format: "%.1f", $0) } ?? "—") · BMI: \(snapshot.bmi.map { String(format: "%.1f", $0) } ?? "—") · Body fat %: \(snapshot.bodyFatPercentage.map { String(format: "%.1f", $0) } ?? "—")"
    }
}
