import Foundation
import HealthKit

/// Turns overlapping ``HKCategorySample`` sleep records into per-night ``SleepSnapshot`` values.
enum SleepAnalysisAggregator {
    static func snapshots(from samples: [HKCategorySample], calendar: Calendar) -> [SleepSnapshot] {
        guard !samples.isEmpty else { return [] }
        let sorted = samples.sorted { $0.startDate < $1.startDate }
        let sessions = splitSessions(sorted)
        return sessions.compactMap { buildSnapshot(samples: $0, calendar: calendar) }
    }

    /// Splits samples into sessions when there is a gap longer than four hours.
    private static func splitSessions(_ sorted: [HKCategorySample]) -> [[HKCategorySample]] {
        var sessions: [[HKCategorySample]] = []
        var current: [HKCategorySample] = []
        let gap: TimeInterval = 4 * 3600
        for sample in sorted {
            if let last = current.last, sample.startDate.timeIntervalSince(last.endDate) > gap {
                sessions.append(current)
                current = [sample]
            } else {
                current.append(sample)
            }
        }
        if !current.isEmpty {
            sessions.append(current)
        }
        return sessions
    }

    private static func buildSnapshot(samples: [HKCategorySample], calendar: Calendar) -> SleepSnapshot? {
        var awake: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var deep: TimeInterval = 0
        var unspecified: TimeInterval = 0
        var inBed: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
            switch value {
            case .inBed:
                inBed += duration
            case .awake:
                awake += duration
            case .asleepREM:
                rem += duration
            case .asleepCore:
                core += duration
            case .asleepDeep:
                deep += duration
            case .asleepUnspecified:
                unspecified += duration
            @unknown default:
                unspecified += duration
            }
        }

        let asleepTotal = rem + core + deep + unspecified
        guard asleepTotal > 0 || inBed > 0 else { return nil }

        let efficiency: Double
        if inBed > 0 {
            efficiency = min(1, max(0, asleepTotal / inBed))
        } else if asleepTotal > 0 {
            efficiency = 1
        } else {
            efficiency = 0
        }

        let anchor = calendar.startOfDay(for: samples.map(\.endDate).max() ?? samples[0].endDate)
        let stages = SleepStages(awake: awake, rem: rem, core: core + unspecified, deep: deep)
        return SleepSnapshot(date: anchor, totalDuration: asleepTotal, efficiency: efficiency, stages: stages)
    }
}
