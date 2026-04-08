import Foundation
import HealthKit

/// Fetches daily activity summaries (steps, energy, distance, exercise, stand).
public final class ActivityProvider {
    private let store: HealthStoreProtocol

    /// Creates a provider that reads from the given HealthKit store abstraction.
    public init(store: HealthStoreProtocol) {
        self.store = store
    }

    /// Fetches an ``ActivitySnapshot`` for today’s calendar day.
    public func today() async throws -> ActivitySnapshot {
        try await date(Date())
    }

    /// Fetches an ``ActivitySnapshot`` for the calendar day containing `date`.
    public func date(_ date: Date) async throws -> ActivitySnapshot {
        try await self.date(date, calendar: Calendar.current)
    }

    /// Fetches one snapshot per calendar day in `range` (inclusive of boundaries).
    public func range(_ range: ClosedRange<Date>) async throws -> [ActivitySnapshot] {
        let cal = Calendar.current
        let start = CalendarDayRange.startOfDay(range.lowerBound, calendar: cal)
        let endDay = CalendarDayRange.startOfDay(range.upperBound, calendar: cal)
        var days: [Date] = []
        var d = start
        while d <= endDay {
            days.append(d)
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        var out: [ActivitySnapshot] = []
        for day in days {
            out.append(try await date(day, calendar: cal))
        }
        return out
    }

    /// Fetches the last `n` calendar days ending today (inclusive).
    public func last(days n: Int) async throws -> [ActivitySnapshot] {
        guard n > 0 else { throw HealthSnapError.noData }
        let cal = Calendar.current
        guard let interval = CalendarDayRange.lastDaysInterval(n, endingAt: Date(), calendar: cal) else {
            throw HealthSnapError.noData
        }
        return try await range(interval.start...(interval.endExclusive.addingTimeInterval(-1)))
    }

    private func date(_ date: Date, calendar: Calendar) async throws -> ActivitySnapshot {
        guard store.isHealthDataAvailable() else { throw HealthSnapError.notAvailable }
        guard let interval = CalendarDayRange.dayInterval(containing: date, calendar: calendar) else {
            throw HealthSnapError.noData
        }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.endExclusive, options: .strictStartDate)

        var sawData = false

        let stepsStats = try await statistics(for: .stepCount, predicate: predicate)
        if stepsStats != nil { sawData = true }
        let steps = Int((try await sum(from: stepsStats, type: .stepCount, unit: HKUnit.count())).rounded())

        let activeStats = try await statistics(for: .activeEnergyBurned, predicate: predicate)
        if activeStats != nil { sawData = true }
        let active = try await sum(from: activeStats, type: .activeEnergyBurned, unit: HKUnit.kilocalorie())

        let basalStats = try await statistics(for: .basalEnergyBurned, predicate: predicate)
        if basalStats != nil { sawData = true }
        let basal = try await sum(from: basalStats, type: .basalEnergyBurned, unit: HKUnit.kilocalorie())

        let distanceStats = try await statistics(for: .distanceWalkingRunning, predicate: predicate)
        if distanceStats != nil { sawData = true }
        let distance = try await sum(from: distanceStats, type: .distanceWalkingRunning, unit: HKUnit.meter())

        let exerciseStats = try await statistics(for: .appleExerciseTime, predicate: predicate)
        if exerciseStats != nil { sawData = true }
        let exerciseMinutes = Int((try await sum(from: exerciseStats, type: .appleExerciseTime, unit: HKUnit.minute())).rounded())

        let standSamples = try await standHourSamples(predicate: predicate)
        if !standSamples.isEmpty { sawData = true }
        let standHours = countStoodHours(samples: standSamples)

        if !sawData {
            throw HealthSnapError.noData
        }

        let dayStart = CalendarDayRange.startOfDay(date, calendar: calendar)
        return ActivitySnapshot(
            date: dayStart,
            steps: steps,
            activeCalories: active,
            totalCalories: active + basal,
            distanceMeters: distance,
            exerciseMinutes: exerciseMinutes,
            standHours: standHours
        )
    }

    private func statistics(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate) async throws -> HKStatistics? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthSnapError.noData
        }
        return try await store.statistics(
            quantityType: type,
            predicate: predicate,
            options: .cumulativeSum
        )
    }

    private func sum(from statistics: HKStatistics?, type identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        guard let statistics, let _ = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }
        guard let sum = statistics.sumQuantity() else {
            return 0
        }
        return sum.doubleValue(for: unit)
    }

    private func standHourSamples(predicate: NSPredicate) async throws -> [HKCategorySample] {
        guard let standType = HKObjectType.categoryType(forIdentifier: .appleStandHour) else {
            return []
        }
        let raw = try await store.samples(
            sampleType: standType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        )
        return raw.compactMap { $0 as? HKCategorySample }
    }

    private func countStoodHours(samples: [HKCategorySample]) -> Int {
        samples.filter { sample in
            sample.value == HKCategoryValueAppleStandHour.stood.rawValue
        }.count
    }
}
