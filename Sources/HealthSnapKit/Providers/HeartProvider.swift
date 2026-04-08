import Foundation
import HealthKit

/// Fetches heart rate averages, resting HR, HRV (SDNN), and per-day samples.
@MainActor
public final class HeartProvider {
    private let store: HealthStoreProtocol

    /// Creates a provider that reads from the given HealthKit store abstraction.
    public init(store: HealthStoreProtocol) {
        self.store = store
    }

    /// Fetches a ``HeartSnapshot`` for today’s calendar day.
    public func today() async throws -> HeartSnapshot {
        try await date(Date())
    }

    /// Fetches a ``HeartSnapshot`` for the calendar day containing `date`.
    public func date(_ date: Date) async throws -> HeartSnapshot {
        try await snapshot(for: date, calendar: .current)
    }

    /// Fetches one snapshot per calendar day in `range`.
    public func range(_ range: ClosedRange<Date>) async throws -> [HeartSnapshot] {
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
        var out: [HeartSnapshot] = []
        for day in days {
            out.append(try await snapshot(for: day, calendar: cal))
        }
        return out
    }

    /// Fetches the last `n` calendar days ending today (inclusive).
    public func last(days n: Int) async throws -> [HeartSnapshot] {
        guard n > 0 else { throw HealthSnapError.noData }
        let cal = Calendar.current
        guard let interval = CalendarDayRange.lastDaysInterval(n, endingAt: Date(), calendar: cal) else {
            throw HealthSnapError.noData
        }
        let upper = interval.endExclusive.addingTimeInterval(-1)
        return try await range(interval.start...upper)
    }

    private func snapshot(for date: Date, calendar: Calendar) async throws -> HeartSnapshot {
        guard store.isHealthDataAvailable() else { throw HealthSnapError.notAvailable }
        guard let interval = CalendarDayRange.dayInterval(containing: date, calendar: calendar) else {
            throw HealthSnapError.noData
        }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.endExclusive, options: [])

        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthSnapError.noData
        }

        let hrStats = try await store.statistics(
            quantityType: hrType,
            predicate: predicate,
            options: .discreteAverage
        )
        let sampleList = try await store.samples(
            sampleType: hrType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        )
        let samples = sampleList.compactMap { $0 as? HKQuantitySample }

        if hrStats == nil, samples.isEmpty {
            throw HealthSnapError.noData
        }

        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let average: Double
        if let hrStats, let q = hrStats.averageQuantity() {
            average = q.doubleValue(for: bpmUnit)
        } else if !samples.isEmpty {
            let values = samples.map { $0.quantity.doubleValue(for: bpmUnit) }
            average = values.reduce(0, +) / Double(values.count)
        } else {
            average = 0
        }

        let resting = try await latestQuantity(
            identifier: .restingHeartRate,
            unit: bpmUnit,
            from: interval.start,
            to: interval.endExclusive
        )

        let hrvMs = try await latestQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli),
            from: interval.start,
            to: interval.endExclusive
        )

        let heartSamples: [HeartSample] = samples.map { sample in
            HeartSample(timestamp: sample.startDate, bpm: sample.quantity.doubleValue(for: bpmUnit))
        }

        let dayStart = CalendarDayRange.startOfDay(date, calendar: calendar)
        return HeartSnapshot(
            date: dayStart,
            averageBPM: average,
            restingBPM: resting,
            hrvSDNN: hrvMs,
            samples: heartSamples
        )
    }

    private func latestQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to endExclusive: Date
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: endExclusive, options: [])
        let list = try await store.samples(
            sampleType: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ).compactMap { $0 as? HKQuantitySample }
        guard let sample = list.first else { return nil }
        return sample.quantity.doubleValue(for: unit)
    }
}
